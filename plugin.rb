# name: discourse-cognito-auth
# about: Authenticate with Cognito
# version: 0.1
# author: Abdullah Alhazmy
# url: https://github.com/alhazmy13/discourse-cognito-auth

enabled_site_setting :cognito_auth_enabled
enabled_site_setting :cognito_app_id
enabled_site_setting :cognito_secure_key
enabled_site_setting :cognito_aws_region
enabled_site_setting :cognito_user_pool_id

gem 'omniauth-cognito-idp', '1.5.0'

class Auth::CognitoAuthenticator < Auth::ManagedAuthenticator

  def name
    "CognitoIdP"
  end

  def enabled?
    SiteSetting.cognito_auth_enabled
  end

  def register_middleware(omniauth)
    omniauth.provider :CognitoIdP,
           setup: lambda { |env|
             strategy = env["omniauth.strategy"]
              strategy.options[:client_id] = SiteSetting.cognito_app_id
              strategy.options[:client_secret] = SiteSetting.cognito_secure_key
              strategy.options[:scope] = 'email openid aws.cognito.signin.user.admin profile'
              strategy.options[:user_pool_id] = SiteSetting.cognito_user_pool_id
              strategy.options[:aws_region] = SiteSetting.cognito_aws_region
           }
  end

  def description_for_user(user)
    info = UserAssociatedAccount.find_by(provider_name: name, user_id: user.id)&.info
    return "" if info.nil?

    info["name"] || info["email"] || ""
  end

  def after_authenticate(auth_token, existing_account: nil)
    # Ignore extra data (we don't need it)
    auth_token[:extra] = {}
    super
  end
end

auth_provider frame_width: 920,
              frame_height: 800,
              authenticator: Auth::CognitoAuthenticator.new

register_svg_icon "fab fa-aws" if respond_to?(:register_svg_icon)

register_css <<CSS
.btn-social.cognito {
  background: #46698f;
}
CSS
