# Redmine Move Comments

The plugin allows you to move a comment made to wrong issue to the right one.

## Features

* Ability to move an issue's comment to another issue
* If you move a comment with issue's field changes or file attachments then just the comment (text field) will be moved. All the changes and files will be left attached to the old issue.

## Screenshot

![Click the 'Edit' button](doc/click-edit-button.png "Click the 'Edit' button")
![Fill the right issue id](doc/fill-the-right-issue-id.png "New field 'Move the comment to another issue'")

## Getting the plugin

A copy of the plugin can be downloaded from GitHub: https://github.com/leanderkretschmer/redmine_move_comments

## Installation

```
cd /path/to/redmine/plugins
git clone https://github.com/leanderkretschmer/redmine_move_comments.git
```

Restart the Redmine.

Migrate is not needed.


To uninstall the plugin migrate the database back and remove the plugin:

```
cd /path/to/redmine/
rm -rf plugins/redmine_move_comments
```

Further information about plugin installation can be found at: http://www.redmine.org/wiki/redmine/Plugins

## Usage

You should be allowed to edit the comments for moving them, i.e. have 'Edit notes' or 'Edit own notes' permissions in Issue tracking section. See details: http://www.redmine.org/projects/redmine/wiki/RedmineRoles

## Compatibility

This version of the plugin is compatible with:
- Redmine 2.4.x and higher
- Redmine 3.x
- Redmine 4.x
- Redmine 5.x
- Redmine 6.x

Tested with Redmine 6.x

## Contribution

## License

This plugin is licensed under the MIT license. See LICENSE-file for details.

## Copyright

Copyright (c) 2015 Mikhail Voronyuk, www.3soft.ru.
