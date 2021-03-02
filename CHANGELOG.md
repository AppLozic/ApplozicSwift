# CHANGELOG

The changelog for [ApplozicSwift](https://github.com/AppLozic/ApplozicSwift). Also see the [releases](https://github.com/AppLozic/ApplozicSwift/releases) on Github.


## [Unreleased]

### Enhancements

- Using the ApplozicCore pod in place of Applozic pod, Now all the Import of Applozic will be changed to ApplozicCore.

## [5.14.0] - 2021-02-27

### Enhancements

- Added an option to change the number of lines of the card template's description label.

## [5.13.0] - 2021-02-16

### Enhancements

- Now, images in image rich message(templateId = 9) can be tapped and previewed just like normal attachment messages.

## [5.12.1] - 2021-02-01

### Fixes

- Fixed an issue where message part of the quick reply and form template was getting truncated from the bottom.

## [5.12.0] - 2021-01-18

### Enhancements

- Added an option to show/hide different message menu options.
- Now, chat bar's attachment color config will be applied to the bottom part of the chat bar as well.

## [5.11.1] - 2020-12-01

### Enhancements
- [CM-486] Show time, state and correct message view's left padding in the all buttons rich message template.
- [CM-507] Enable screen transition animations in all screens.

### Fixes
- Fixed an issue where back button action in the conversation screen was not opening correct screen.
- Fixed an issue where in some cases conversation was not switching when we open it through notification from background.

## [5.11.0] - 2020-10-27

### Enhancements
- [CM-402] Date picker support in form template.
- [CM-402] Text validation support in form template.
- [CM-451] Add support for setting a prefilled message to send before launching a chat.
- [CM-480] Added config for changing textview's text and placeholder style
 </br> Use the below config to change the style:

```swift
// Text view's placeholder style
ALKChatBarConfiguration.TextView.placeholder = Style(font: .font(.normal(size: 16)), text: .gray)

// Text view's text style
ALKChatBarConfiguration.TextView.text = Style(font: .font(.normal(size: 18)), text: .black)
```
- [CM-411] Show new Photos UI in iOS 14+ devices to send images/videos without giving full access to the library.

## [5.10.2] - 2020-10-06

### Fixes
- Fixed an issue where button tap in form template was not working in iOS 14.
- [CM-481] Sender's profile image and name will be shown in the all buttons rich message template.

## [5.10.0] - 2020-09-09

### Enhancements
- [CM-380] Support HTML message type with rich messages.
- [CM-213] Added support for sharing photos saved on iCloud.
- [CM-383] Added speech to text support.

## [5.9.2] - 2020-08-21

### Enhancements
- Removed the line limit of form selection items to allow dynamic text of any size.

## [5.9.1] - 2020-08-18

### Enhancements
- [CM-426] Increased the line limit of form selection items.

### Fixes
- Fixed issue where message metadata coming as nil in some cases.

## [5.9.0] - 2020-08-14

### Enhancements
- [CM-384] Added document sharing support.
### Fixes
- [CM-417] Fixed a crash that occurred in iOS 13.5 after going back from the group detail or document viewer to a conversation thread.

## [5.8.2] - 2020-07-24

### Fixes
- Fixed the issue in attachments download.

## [5.8.1] - 2020-07-23

### Fixes
- Fixed the issue where form data submit was using data from previous cell.

## [5.8.0] - 2020-07-15

### Enhancements
- [CM-22] Add form template support in the rich messages.

## [5.7.1] - 2020-07-06

### Fixes
- [CM-354] Fixed audio playing issue when changing chat threads.

## [5.7.0] - 2020-06-23

### Enhancements
- Migrated to Swift 5

### Fixes
- [CM-281] Fixed "no results found" error when opening a location message.

## [5.6.0] - 2020-06-08

### Fixes
[CM-276] Fixed a crash in MQTT subscription

## [5.5.0] - 2020-05-25

### Enhancements
-[CM-224] Add support for rich message templates without any text message

## [5.4.0] - 2020-05-07

### Enhancements

- Show link preview in chat for web links
</br>You can use below config to disable web link preview in chat:
```
    config.isLinkPreviewDisabled = true
```
You need to set `Allow Arbitrary` Loads to YES on your project's `Info.plist` file.
```
 <key>NSAppTransportSecurity</key>
  <dict>
      <key>NSAllowsArbitraryLoads</key>
      <true/>
  </dict>
```
If you don't want to use the above option, You can white list some the websites which you want to allow them in `Info.plist` file
```
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <false/>
  <key>NSExceptionDomains</key>
  <dict>
    <key>google.com</key>
    <dict>
      <key>NSIncludesSubdomains</key>
      <true/>
      <key>NSExceptionAllowsInsecureHTTPLoads</key>
      <true/>
    </dict>
  </dict>
</dict>
```
You can read more on Property List Keys
[here](https://developer.apple.com/documentation/bundleresources/information_property_list/nsapptransportsecurity/nsexceptiondomains)

### Fixes
- [CM-146] Fixed back button issue in searched conversation view.
- [CM-241] Fixed a crash that could happen when some message updates are delayed.
- [CM-225] Fixed an issue where group profile was getting removed on group name update.

## [5.3.0] - 2020-04-21

### Enhancements

- [CM-193] Added support to open the application when tapping any URL in the text message. If the application isn't installed, we'll open it in Safari.

### Fixes

- [CM-201] Fixed an issue where the footer of the sender-side view of email messages overlapped with the header, as there were no constraints.
- [CM-146] Fixed search messages loading issue.

## [5.2.0] - 2020-03-31

### Enhancements
- Customize the date and info message font, text color or background color of the view
</br>Use the below config to change the style of date separator and channel info messages:

```
   ALKMessageStyle.infoMessage = Style(font: UIFont.systemFont(ofSize: 12), text: UIColor.black , background: .red)

   ALKMessageStyle.dateSeparator = Style(font: UIFont.systemFont(ofSize: 12), text: UIColor.black, background: .red)
```

## [5.1.1] - 2020-03-04

### Fixes
-[CM-136] RichMessage button UI issue

## [5.1.0] - 2020-03-03

### Enhancements
- Added support for syncing package details when a suspension screen is shown.
- Added an option to change message status(read receipt) style. Now icon for message status can be changed from outside or it can be hidden.
- Added a config to disable in-app notification banner.
</br>You can use below config to disable in-app notification banner:
```
	config.isInAppNotificationBannerDisabled = true
```

## [5.0.0] - 2020-02-14

### Enhancements
- Added save photo button in the media viewer.

### Fixes
- If the keyboard used is not English, the keyboard is changed. (.asciiCapable -> .emailAddress)
- [CM-141] Fixed an issue where messages were deleted after leaving the group.
- [CM-142] Fixed back button alignment issue in the Conversation screen.
- [CM-133] Fixed an issue where updating certain localizable strings from a custom localizable file did not work.

## [4.1.0] - 2020-01-27

### Enhancements

- [CM-51] Email message layout improvement.

## [4.0.1]
---
### Fixes

- Fixed an issue where button's title was sent as a message in card template.

## [4.0.0]
---
### Enhancements
- [AL-3826] Reply message will be shown in a popup when it is not visible in the list.
- Now user's display name will be shown instead of group name in case of `GROUP_OF_TWO`.

### Fixes
- Fixed an issue where navigation bar's back button color was not changing using `UIAppearance`.
- Fixed all the warnings.

## [3.4.0]
---
### Enhancements
- Added support for iOS 13.
- [AL-3761] Added support for member mention in groups.
- [AL-3741] Added support for rich message template 11.
- [AL-3847] Updated UI for link button and refractored rich messages to use same view for all types of buttons.
- [AL-3642] Added support for message search.
- [AL-3853] Added support for navigation bar customization using `UIAppearance`. See `MIGRATING.md` for more details.
- [AL-3852] Added setting for adding border to message bubble.
This setting will only take effect with round bubble and will only work with text messages, audio messages and contact messages. For other messages the setting will have no effect.
Below is the sample code to illustrate how to use this setting:
```
        ALKMessageStyle.sentBubble.style = .round
        ALKMessageStyle.sentBubble.border.color = UIColor.blue
        ALKMessageStyle.sentBubble.border.width = 2

        ALKMessageStyle.receivedBubble.style = .round
        ALKMessageStyle.receivedBubble.border.color = UIColor.red
        ALKMessageStyle.receivedBubble.border.width = 2
```
- Back button on Chat screen will now just pop. Earlier it was going back to the root view controller.
- [AL-3854] We will now show mute icon in chat list when the conversation is muted.
The mute icon image can be changed from outside using below code.
```
        ALKChatCell.Config.iconMuted = "PASS_YOUR_IMAGE_HERE"
```

### Fixes
- [AL-3862] Fixed a crash where dbMessage was being forcefully unwrapped.

## [3.3.0]
---
### Enhancements
-[AL-3648] Option to zoom in Picture preview screen.
-[AL-3738] Added font and color customizations configuration for group detail screen.

## [3.2.0]
---
### Enhancements
- [AL-3647] Send notification for mute, block and add member click
- [AL-3620] Added an option to open message in browser option for email messages.

### Fixes
- Fixed an issue where duplicate messages were getting added in the chat thread from notifications.

## [3.1.0]
---
### Enhancements
- [AL-3580] Added separate config options for the chat bar items.
- [AL-3577] Added Option to report a message;
- [AL-3540] Added custom button in the navigation bar
- [AL-3210] Added RTL support.
- [AL-3624] Added support for passing regular expression pattern to restrict certain messages.

## [3.0.0]
---
### Enhancements
- [AL-3623] Now iOS 10 is the minimum version supported.
- [AL-3603] Now calculated height of message cell will be cached.
- [AL-2918] Added support for FAQ Template rich message and removed Generic List rich message.
- [AL-3395] Added support to detect links in message.

### Fixes
- Fixed a crash when video isn't exported properly.

## [2.7.0]
---

### Enhancements
- [AL-3391] Add support for autosuggestions.
- Added setting to hide contact-share option in chatbar.
- Added setting to disable swipe action in chat list.
- [AL-3253] Added support for Image rich message. Which means an image message can be rendered by passing image URL and the caption in JSON format.
- [AL-3396] Added support for context-based group_of_two conversation.

### Fixes
- [AL-3533] Fixed an issue where scrolling in group detail screen would cause inconsistency in profile images of participants.
- [AL-3533] Fixed an issue where app was crashing while removing table viewcontroller.
- [AL-3548] Fixed an issue where app was crashing after tapping on notification.
- Now, group title action will be disabled for support group(GroupType = 10) as well.

## [2.6.0]
---
### Enhancements
- [AL-3397] Added support for sharing contacts.
- [AL-3446] Added remove from group, make admin, dismiss admin features in group details page.
- Now tapping on user title in navigation bar for 1-1 chat will fire a notification which can be handled from outside.

### Fixes
- Fixed an issue where user was shown "Not part of group" which was happening because fetch request for group members was giving null.


## [2.5.1]

### Enhancments
- [AL-3490] Added support for Back button action in Conversation VC if the VC is presented not pushed.

### Fixes
- [AL-3486]Fixed an issue where in some cases view was in an incorrect state if the keyboard is visible.

## [2.5.0]
---
### Enhancements
- [AL-3301] Added a way to use custom view for in-app notifications.
- [AL-3280] Added support for profanity filter. To enable this feature set the filename of the profane words list in the configuration.
- [AL-3012] Docs rendering and opening support. Added support for PDF, doc, txt and some other document sharing formats.
- [AL-3303] Added support for different storage schemes.

### Fixes
- Fixed an issue where in some cases removed group member was able to send an audio message.
- Resolved an issue where Block/Unblock was not reflecting in real-time.

## [2.4.0]
---
### Enhancements
- [AL-3267] Added support for blocking/unblocking a user.

### Fixes
- [AL-3302] Fix duplicate messages for open group.
- Fixed an issue where conversation details weren't getting refreshed when chat was opened from tapping on notification.
- [AL-3307] Fixed an issue where typing indicator in 1-1 chat when user was typing in group.
- [AL-3312] Fixed an issue where profile image of receiver wasn't visible for video cells.
-  Fixed an issue where video weren't being send after recording from the SDK.
- Fixed an issue where changing the right nav bar conversation icon was still refreshing the view.
-  Fixed issue where style was not used for text message sent and received.

## [2.3.0]
---
### Enhancments
- Updates Swift version to 4.2
- Added Online/LastSeen status at navigation bar in conversation detail screen.
- Show loading indicator at navigation bar till conversation details are fetched.
- [AL-3206] Added support for new richMessage type : `ListTemplate` and deprecated `ALKGenericList`
- [AL-3206] Added support for new richMessage type : `CardTemplate` and deprecated `ALKGenericCard`
- [AL-3203] Removed the bubble image icon and added the corner Radius

   You can change the corner Radius like below:
```
        ALKMessageStyle.receivedBubble.cornerRadius = 12
        ALKMessageStyle.sentBubble.cornerRadius = 12

        ALKMessageStyle.receivedBubble.color = UIColor.gray
        ALKMessageStyle.sentBubble.color = UIColor.gray

        ALKMessageStyle.sentBubble.style = .edge
        ALKMessageStyle.receivedBubble.style = .edge
```     
- [AL-3229] Added caption support with image attachments. If the message(text) is present then it will be shown as caption.   
- [AL-3257] Added receive and sent message style. This is how you can change the styles:

```
        ALKMessageStyle.receivedMessage = Style(font: Font.bold(size: 14).font(), text: UIColor.red)
        ALKMessageStyle.sentMessage = Style(font: Font.italic(size: 14).font(), text: UIColor.green)
```
- Added email message support.

## [2.2.0]
---
### Enhancments

-[AL-3196] Add a config option to disable the rich message button clicks.
- Now message key will also come in the click action for rich messages.
- Updated send button padding to make both height and width same.

### Fixes

-[AL-3224] Fixed an issue where changing background color was not updating the background of conversation view.
-[AL-3240] Fixed an where clicking mute/unmute and if the title is large then it was going out of screen.
-[AL-3241] Fixed an issue where if we update the name it was also updating the group icon.

## [2.1.0]
---
### Enhancements

-[Al-3137] Change quick reply view to a staggered grid layout.
-[AL-3137] Added support for submit button and link button as rich messages.

### Fixes
- Fixed an issue where view was taking time in moving upwards when keyboard appears in the screen.

## [2.0.0]
---
### Fixes

- [AL-3170] Fixed a memory leak issue in ALKConversationViewController.

### Enhancements

- [AL-2856] Dismiss Typing indicator in 30 seconds if stop flag not received
- [AL 3136] Default message meta data configuration
- Use the same bubble in case of menu click show and hide if style setting is passed

## [1.3.0]
---
### Enhancements

- [AL-2856] Added a header view in chat bar to inject custom views from outside.
- [AL-3044] Added ALKConversationListDelegate to get chat thread selection callback.
	 And updated properties of `ALKChatViewModelProtocol` to public.
- [AL-2923] Added configure for hide start new in empty conversation
- [AL-2923] Added configure for hide back button in conversation list
- [AL-2923] Added configure for changing  color in navigation title
- [Al-3093] Update rich message layout to display message on top of templates.
- [AL-3131] Update notification to support context-based-chat.
- [AL-3088] Separate tableview from ConversationListViewController.

### Fixes

- [AL-3056] Fix an issue where earlier conversation won't load when scrolled to top.
- [AL-2923] Fix the crash for media cells for localization file name.
- [Al-3123] Fix an issue where notification will come for the message sent by the logged in user from different device.
- [AL-3117] Refresh conversationView when it is opened.

## [1.2.0]
---
### Enhancements
- [AL-3004] Update chat screen to enable/disble chat for user when user is added/removed in the group.
- [AL-2944] Update mute functionality in conversation view.
- [AL-2922] Option to configure icon of navigation bar for conversation view and conversation list view.
- [AL-2922] Option to configure icon of send message button.
- [AL-2922] Option to configure line image visibility in chat bar.
- [AL-2922] Option to enable custom handling of navigation item click in conversation view.
- [CS-174] Update typing status to show display name of user in group conversation.
- [AL-2921] Add localization support.
- [AL-2928] UI Test case for audio recording view.

### Fixes
- [AL-3022] Fix an issue where audio option was still visible for open group.
- [AL-2973] Fix an issue where notification won't come for messages when chat screen is open.

## [1.1.0]
---
### Fixes
- Fix position of audio-mic button. When coming back from photos screen or location screen position of mic button moves to left of screen.
- [AL-2932] Fix removal of group from chat list after group is left by swiping right on group.
- [AL-2920] Fix an issue where chat, opened from tapping on push notification, won't scroll to latest message.
- [AL-2978] Fix an issue where new one to one chat from a user would overlap all the groupChats in which this user has sent last message.
- [CS-169] Fix trimming of launch-page start to chat text in iPhone 5s.

## [1.0.0]
---
### Enhancements
- [AL-2875] New swipe based design for audio recording.
- [AL-2769] Quick reply support in messages

### Fixes
- [AL-2909] Fix trimming of  multiline message

## [0.15.1]
---
### Fixes
- [AL-2908] Fixed message character going out of bounds.
- [CS-127] Fixed an issue where tapping on notification was not opening chat screen.

## [0.15.0]
---
### Enhancements
- [CS-108] Add support for contacts group.

### Fixes
- [AL-2885] Fixed a crash when tapping on add member in Create group screen.
- [AL-2885] Fixed a crash when tapping on add member in Create group screen.
- [AL-2885] Fixed a crash when tapping on add member in Create group screen.
- [AL-2885] Fixed a crash when tapping on add member in Create group screen.
- [AL-2885] Fixed a crash when tapping on add member in Create group screen.
- [AL-2885] Fixed a crash when tapping on add member in Create group screen.
- [AL-2885] Fixed a crash when tapping on add member in Create group screen.
- [AL-2885] Fixed a crash when tapping on add member in Create group screen.
- [AL-2885] Fixed a crash when tapping on add member in Create group screen.
- [AL-2885] Fixed a crash when tapping on add member in Create group screen.
- [AL-2885] Fixed a crash when tapping on add member in Create group screen.
- [AL-2885] Fixed a crash when tapping on add member in Create group screen.
- [AL-2885] Fixed a crash when tapping on add member in Create group screen.
- [AL-2885] Fixed a crash when tapping on add member in Create group screen.
- [AL-2885] Fixed a crash when tapping on add member in Create group screen.
- [AL-2885] Fixed a crash when tapping on add member in Create group screen.
- [AL-2885] Fixed a crash when tapping on add member in Create group screen.
- [AL-2885] Fixed a crash when tapping on add member in Create group screen.
- [AL-2885] Fixed a crash when tapping on add member in Create group screen.
- [AL-2885] Fixed a crash when tapping on add member in Create group screen.
- [AL-2885] Fixed a crash when tapping on add member in Create group screen.
- [AL-2885] Fixed a crash when tapping on add member in Create group screen.
- [AL-2885] Fixed a crash when tapping on add member in Create group screen.
- [AL-2885] Fixed a crash when tapping on add member in Create group screen.
- [AL-2885] Fixed a crash when tapping on add member in Create group screen.
