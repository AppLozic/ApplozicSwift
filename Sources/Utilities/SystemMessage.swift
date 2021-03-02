//
//  SystemMessage.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Foundation

// handle all in app's display messages
struct SystemMessage: Localizable {
    enum Camera {
        static let cameraPermission = localizedString(forKey: "EnableCameraPermissionMessage")
        static let CamNotAvailable = localizedString(forKey: "CameraNotAvailableMessage")
        static let camNotAvailableTitle = localizedString(forKey: "CameraNotAvailableTitle")
        static let GalleryAvailable = localizedString(forKey: "GalleryNotAvailableMessage")
        static let PictureCropped = localizedString(forKey: "ImageCroppedMessage")
        static let PictureReset = localizedString(forKey: "ImageResetMessage")
        static let PleaseAllowCamera = localizedString(forKey: "PleaseAllowCamera")
    }

    enum Contact {
        static let permissionMessage = localizedString(forKey: "EnableContactPermissionMessage")
    }

    enum Microphone {
        static let MicNotAvailable = localizedString(forKey: "MicrophoneNotAvailableMessage")
        static let PleaseAllowMic = localizedString(forKey: "AllowSoundRecordingMessage")
        static let SlideToCancel = localizedString(forKey: "SlideToCancelMessage")
        static let Recording = localizedString(forKey: "RecordingMessage")
        static let SpeechToTextPlaceholder = localizedString(forKey: "SpeechToTextPlaceholder")
    }

    enum Map {
        static let ShareLocationTitle = localizedString(forKey: "ShareLocationTitle")
        static let SendLocationButton = localizedString(forKey: "SendLocationButton")
    }

    enum Information {
        static let FriendAdded = localizedString(forKey: "FriendAddedMessage")
        static let FriendRemoved = localizedString(forKey: "FriendRemovedMessage")
        static let AppName = ""
        static let NotPartOfGroup = localizedString(forKey: "NotPartOfGroup")
        static let UnblockToEnableChat = localizedString(forKey: "UnblockToEnableChat")
        static let ChatHere = localizedString(forKey: "ChatHere")
        static let LoadingIndicatorText = localizedString(forKey: "LoadingIndicatorText")
        static let ReportMessageSuccess = localizedString(forKey: "ReportMessageSuccess")
        static let ReportMessageError = localizedString(forKey: "ReportMessageError")
        static let ReportAlertTitle = localizedString(forKey: "ReportAlertTitle")
        static let ReportAlertMessage = localizedString(forKey: "ReportAlertMessage")
        static let ReportInfoMessage = localizedString(forKey: "ReplyInfoMessage")
        static let FailedToLoadLink = localizedString(forKey: "FailedToLoadLink")
        static let ExportLoadingIndicatorText = localizedString(forKey: "ExportLoadingIndicatorText")
    }

    enum Update {
        static let CheckRequiredField = localizedString(forKey: "CheckImageAndNameField")
        static let UpdateMood = localizedString(forKey: "UpdateMoodMessage")
        static let UpdateProfileName = localizedString(forKey: "UpdateProfileSuccessMessage")
        static let Failed = localizedString(forKey: "FailedToUpdateMessage")
    }

    enum Warning {
        static let NoEmail = localizedString(forKey: "EnterEmailMessage")
        static let InvalidEmail = localizedString(forKey: "InvalidEmailMessage")
        static let FillInAllFields = localizedString(forKey: "Please fill-in all fields")
        static let FillInPassword = localizedString(forKey: "FillPasswordMessage")
        static let PasswordNotMatched = localizedString(forKey: "PasswordNotMatchedMessage")
        static let CamNotAvaiable = localizedString(forKey: "CamNotAvaiable")
        static let Cancelled = localizedString(forKey: "CancelMessage")
        static let PleaseTryAgain = localizedString(forKey: "ConnectionFailedMessage")
        static let NetworkAccessFailedMessage = localizedString(forKey: "NetworkAccessFailedMessage")
        static let FetchFail = localizedString(forKey: "FetchFailedMessage")
        static let OperationFail = localizedString(forKey: "OperationFailedMessage")
        static let DeleteSingleConversation = localizedString(forKey: "DeleteSingleConversation")
        static let LeaveGroupConoversation = localizedString(forKey: "LeaveGroupConversation")
        static let DeleteGroupConversation = localizedString(forKey: "DeleteGroupConversation")
        static let DeleteContactWith = localizedString(forKey: "RemoveMessage")
        static let DownloadOriginalImageFail = localizedString(forKey: "DownloadOriginalImageFail")
        static let ImageBeingUploaded = localizedString(forKey: "UploadingImageMessage")
        static let SignOut = localizedString(forKey: "SignOutMessage")
        static let FillGroupName = localizedString(forKey: "FillGroupName")
        static let DiscardChange = localizedString(forKey: "DiscardChangeMessage")
        static let profaneWordsTitle = localizedString(forKey: "profaneWordsTitle")
        static let profaneWordsMessage = localizedString(forKey: "profaneWordsMessage")
        static let videoExportError = localizedString(forKey: "VideoExportError")
    }

    enum ButtonName {
        static let SignOut = localizedString(forKey: "SignOutButtonName")
        static let Retry = localizedString(forKey: "RetryButtonName")
        static let Remove = localizedString(forKey: "RemoveButtonName")
        static let Leave = localizedString(forKey: "LeaveButtonName")
        static let Cancel = localizedString(forKey: "ButtonCancel")
        static let CapitalLetterCancelText = localizedString(forKey: "CapitalLetterCancelText")
        static let Discard = localizedString(forKey: "ButtonDiscard")
        static let Save = localizedString(forKey: "SaveButtonTitle")
        static let ResetPhoto = localizedString(forKey: "ResetPhotoButton")
        static let Select = localizedString(forKey: "SelectButton")
        static let Done = localizedString(forKey: "DoneButton")
        static let Invite = localizedString(forKey: "InviteButton")
        static let Confirm = localizedString(forKey: "ConfirmButton")
        static let ReportMessage = localizedString(forKey: "ReportMessage")
        static let Delete = localizedString(forKey: "DeleteButtonName")
        static let ok = localizedString(forKey: "OkMessage")
        static let okay = localizedString(forKey: "OkayMessage")
    }

    enum NoData {
        static let NoName = localizedString(forKey: "NoNameMessage")
    }

    enum UIError {
        static let unspecifiedLocation = localizedString(forKey: "UnspecifiedLocation")
        static let InvalidDatErrorInForm = localizedString(forKey: "InvalidDatErrorInForm")
    }

    enum PhotoAlbum {
        static let Success = localizedString(forKey: "PhotoAlbumSuccess")
        static let Fail = localizedString(forKey: "PhotoAlbumFail")
        static let SuccessTitle = localizedString(forKey: "PhotoAlbumSuccessTitle")
        static let FailureTitle = localizedString(forKey: "PhotoAlbumFailureTitle")
        static let Ok = localizedString(forKey: "PhotoAlbumOk")
        static let PreviewTitle = localizedString(forKey: "RichMessageImagePreviewTitle")
    }

    enum Message {
        static let isTypingForRTL = localizedString(forKey: "IsTypingForRTL")
        static let isTyping = localizedString(forKey: "IsTyping")
        static let areTyping = localizedString(forKey: "AreTyping")
    }

    enum ChatList {
        static let title = localizedString(forKey: "ConversationListVCTitle")
        static let NoConversationsLabelText = localizedString(forKey: "NoConversationsLabelText")
        static let leftBarBackButton = localizedString(forKey: "Back")
    }

    enum Chat {
        static let somebody = localizedString(forKey: "Somebody")
    }

    enum NavbarTitle {
        static let createGroupTitle = localizedString(forKey: "CreateGroupTitle")
        static let editGroupTitle = localizedString(forKey: "EditGroupTitle")
        static let emailWebViewTitle = localizedString(forKey: "EmailWebViewTitle")
    }

    enum LabelName {
        static let Edit = localizedString(forKey: "Edit")
        static let Participants = localizedString(forKey: "Participants")
        static let TypeGroupName = localizedString(forKey: "TypeGroupName")
        static let SendPhoto = localizedString(forKey: "SendPhoto")
        static let Settings = localizedString(forKey: "Settings")
        static let Camera = localizedString(forKey: "Camera")
        static let Cancel = localizedString(forKey: "Cancel")
        static let CropImage = localizedString(forKey: "CropImage")
        static let Photos = localizedString(forKey: "PhotosTitle")
        static let SendVideo = localizedString(forKey: "SendVideo")
        static let SearchPlaceholder = localizedString(forKey: "SearchPlaceholder")
        static let NewChatTitle = localizedString(forKey: "NewChatTitle")
        static let AddToGroupTitle = localizedString(forKey: "AddToGroupTitle")
        static let InviteMessage = localizedString(forKey: "InviteMessage")
        static let DiscardChangeTitle = localizedString(forKey: "DiscardChangeTitle")
        static let NotNow = localizedString(forKey: "NotNow")
        static let Copy = localizedString(forKey: "Copy")
        static let Reply = localizedString(forKey: "Reply")
        static let Report = localizedString(forKey: "Report")
        static let You = localizedString(forKey: "You")
        static let Admin = localizedString(forKey: "Admin")
        static let DatePickerTimeTitle = localizedString(forKey: "DatePickerTimeTitle")
        static let DatePickerDateTitle = localizedString(forKey: "DatePickerDateTitle")
        static let DatePickerDateAndTimeTitle = localizedString(forKey: "DatePickerDateAndTimeTitle")
    }

    enum Mute {
        static let MuteUser = localizedString(forKey: "MuteUser")
        static let MuteChannel = localizedString(forKey: "MuteChannel")
        static let UnmuteUser = localizedString(forKey: "UnmuteUser")
        static let UnmuteChannel = localizedString(forKey: "UnmuteChannel")
        static let MuteButton = localizedString(forKey: "MuteButton")
        static let UnmuteButton = localizedString(forKey: "UnmuteButton")
    }

    enum MutePopup {
        static let EightHour = localizedString(forKey: "EightHour")
        static let OneWeek = localizedString(forKey: "OneWeek")
        static let OneYear = localizedString(forKey: "OneYear")
    }

    enum UserStatus {
        static let Online = localizedString(forKey: "Online")
        static let LastSeen = localizedString(forKey: "LastSeen")
        static let JustNow = localizedString(forKey: "JustNow")
        static let MinutesAgo = localizedString(forKey: "MinutesAgo")
        static let HoursAgo = localizedString(forKey: "HoursAgo")
    }

    enum Block {
        static let BlockTitle = localizedString(forKey: "BlockTitle")
        static let UnblockTitle = localizedString(forKey: "UnblockTitle")
        static let BlockUser = localizedString(forKey: "BlockUser")
        static let UnblockUser = localizedString(forKey: "UnblockUser")
        static let ErrorMessage = localizedString(forKey: "ErrorMessage")
        static let OkMessage = localizedString(forKey: "OkMessage")
        static let BlockSuccess = localizedString(forKey: "BlockSuccess")
        static let UnblockSuccess = localizedString(forKey: "UnblockSuccess")
    }

    enum GroupDetails {
        static let AddParticipant = localizedString(forKey: "AddParticipant")
        static let RemoveUser = localizedString(forKey: "RemoveUser")
        static let MakeAdmin = localizedString(forKey: "MakeAdmin")
        static let DismissAdmin = localizedString(forKey: "DismissAdmin")
        static let SendMessage = localizedString(forKey: "SendMessage")
        static let RemoveFromGroup = localizedString(forKey: "RemoveFromGroup")
        static let Info = localizedString(forKey: "Info")
    }
}
