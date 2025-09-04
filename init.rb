require 'redmine'
require_relative 'lib/move_comments_hooks'

Redmine::Plugin.register :redmine_move_comments do
  name 'Redmine Move Comments plugin'
  author 'Leander Kretschmer'
  description 'Redmine move comments plugin'
  version '0.1.0'
  requires_redmine :version_or_higher => '6.0.0'
  url 'https://github.com/leanderkretschmer/redmine_move_comments'
  
  settings :default => {
    'show_user_tickets' => '0'
  }, :partial => 'settings/move_comments_settings'
end
