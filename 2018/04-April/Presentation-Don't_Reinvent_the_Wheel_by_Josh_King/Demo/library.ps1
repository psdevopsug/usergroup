
[guid]::NewGuid()

#region External DLL
Add-Type -Path C:\ReinventWheel\lib\Microsoft.Toolkit.Uwp.Notifications.dll

#region New Object
$UwpText = [Microsoft.Toolkit.Uwp.Notifications.AdaptiveText]::new()
$UwpText
#endregion

[Microsoft.Toolkit.Uwp.Notifications.BindableString]::('test')


#region Properties
$UwpText.Text = 'Hello'
$UwpText.HintMinLines = 1
$UwpText.HintMaxLines = 2
$UwpText.HintWrap = $true
#endregion

#region Result
$UwpText
$UwpText | Get-Member
#endregion
#endregion