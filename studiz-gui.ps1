#Interface til opslag af brugere AD'et, for der efter at slå op i Studiz for et billede af brugeren

#region Modules installed
# Check if the ActiveDirectory module is installed
if (Get-Module -ListAvailable -Name ActiveDirectory) {
    #Write-Host "ActiveDirectory module is already installed."
} else {
    If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){
        # Prompt the user to install the ActiveDirectory module
        $install = Read-Host "The ActiveDirectory module is not installed. Would you like to install it? (Y/N)"
        if ($install -eq "Y" -or $install -eq "y") {
            # Relaunch as an elevated process:
            Start-Process powershell.exe "-File",('"{0}"' -f $MyInvocation.MyCommand.Path) -Verb RunAs
            exit
        } else {
            exit
        }
    }
        # Install the ActiveDirectory module
        Write-Host "Installing the ActiveDirectory module..."
        #Sætter registerings nøgle til at bruge Windows update service
        $useWUServer = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "UseWUServer"
        if ($useWUServer -eq 1) {Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "UseWUServer" -Value 0}
        Restart-Service -Name "wuauserv" -Force
        Get-WindowsCapability -Name Rsat.ActiveDirectory* -Online | Add-WindowsCapability -Online
        Write-Host "The ActiveDirectory module has been installed."
}

#endregion Modules installed

#region Hide Gui
#Powershell Console minimeres
$Script:showWindowAsync = Add-Type -MemberDefinition @"
[DllImport("user32.dll")]
public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
"@ -Name "Win32ShowWindowAsync" -Namespace Win32Functions -PassThru
Function Show-Powershell(){$null = $showWindowAsync::ShowWindowAsync((Get-Process -Id $pid).MainWindowHandle, 10)}
Function Hide-Powershell(){$null = $showWindowAsync::ShowWindowAsync((Get-Process -Id $pid).MainWindowHandle, 2)}

#Hvis scriptet er startet fra ISE skal den ikke gemmes
if ($host.Name -ne 'Windows PowerShell ISE Host') {Hide-Powershell}
#endregion Hide Gui

#Skifter visning af gruppe medlemskab så den kun viser gruppe navne som starter med fag
$Version = "1.0"
$Viskunfag = $true
$Global:bahfail = $null #TODO find løsning til denne hack
$Global:OriPhoto =$null
Add-Type -AssemblyName System.Windows.Forms
Import-Module ActiveDirectory

#region Skole opsætning
$key = @(13, 75, 57, 2, 11, 153, 121, 188, 101, 1, 0, 147, 55, 237, 81, 76, 23, 3, 92, 32, 1, 9, 204, 52)
$AuthToken = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR((Get-Content "C:\dat\X\X\Studiz\studiz.txt" | ConvertTo-SecureString -Key $key)))
$key = $null
$BaseUrl = "https://www.studiz.dk"
$AllPhotoURL = "/api/v3/study_id_photos?institution_id="
$StudentPhotoUrl = "/api/v3/study_id_photos?student_id="
$InstitutionID = "471"
$headers = @{Authorization = "Token token=`"$AuthToken`""}
#endregion Skole opsætning

#region Icon
# here's the base64 string
$base64 = "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"
 
# Create a streaming image by streaming the base64 string to a bitmap streamsource
$bitmap = New-Object System.Windows.Media.Imaging.BitmapImage
$bitmap.BeginInit()
$bitmap.StreamSource = [System.IO.MemoryStream][System.Convert]::FromBase64String($base64)
$bitmap.EndInit()
$bitmap.Freeze()
 
# Convert the bitmap into an icon
$image = [System.Drawing.Bitmap][System.Drawing.Image]::FromStream($bitmap.StreamSource)
$icon = [System.Drawing.Icon]::FromHandle($image.GetHicon())
#endregion Icon

#region ; Gui
#made with https://poshgui.com/#
$Form = New-Object system.Windows.Forms.Form 
$Form.Text = "Studiz lookup " + $Version
$form.AutoSize = $true
$form.AutoSizeMode = 'GrowAndShrink'
$form.AutoScaleMode = 'Dpi'
$form.AutoScaleDimensions = '96, 96'
$form.Padding = '10, 10, 10, 10'
$Form.TopMost = $false
$Form.Icon = $icon

$Form.FormBorderStyle = 'Fixed3D'
$Form.MaximizeBox = $false
#$Icon = New-Object system.drawing.icon ("Tools.ico")
#$Form.Icon = $Icon

$UserorCompLabel = New-Object system.windows.Forms.Label 
$UserorCompLabel.Text = "Brugernavn eller navn"
$UserorCompLabel.AutoSize = $true
$UserorCompLabel.Width = 25
$UserorCompLabel.Height = 10
$UserorCompLabel.location = new-object system.drawing.point(15,10)
$UserorCompLabel.Font = "Georgia,10"
$Form.controls.Add($UserorCompLabel) 

$UserInputBox = New-Object system.windows.Forms.TextBox 
$UserInputBox.Width = 120
$UserInputBox.Height = 21
$UserInputBox.location = new-object system.drawing.point(16,32)
$UserInputBox.Font = "Georgia,10"
$Form.controls.Add($UserInputBox)

$ADLookupBT = New-Object system.windows.Forms.Button 
$ADLookupBT.Text = "Søg"
$ADLookupBT.Width = 120
$ADLookupBT.Height = 30
$ADLookupBT.location = new-object system.drawing.point(16,60)
$ADLookupBT.Font = "Georgia,10"
$ADLookupBT.Add_Click({ADLookupBT_Click})
#Håndtere når man trykker på Enter i $UserInputBox, og beeper ikke?!
$Form.AcceptButton = $ADLookupBT

$Form.controls.Add($ADLookupBT)

$GroupLabel = New-Object system.windows.Forms.Label 
$GroupLabel.Text = "Gruppe medlemskab:"
$GroupLabel.AutoSize = $true
$GroupLabel.Width = 25
$GroupLabel.Height = 10
$GroupLabel.location = new-object system.drawing.point(710,11)
$GroupLabel.Font = "Georgia,10"
$Form.controls.Add($GroupLabel) 

$GroupListBox = New-Object system.windows.Forms.ListBox 
$GroupListBox.Width = 313
$GroupListBox.Height = 204
$GroupListBox.location = new-object system.drawing.point(711,36)
$GroupListBox.Sorted = $True
$GroupListBox.Font = "Georgia,11"
$Form.controls.Add($GroupListBox) 

$Info1TB = New-Object system.windows.Forms.TextBox
$Info1TB.Text = ""
$Info1TB.AutoSize = $true
$Info1TB.Width = 400
$Info1TB.Height = 10
$Info1TB.ReadOnly = $true
$Info1TB.location = new-object system.drawing.point(16,100)
$Info1TB.Font = "Georgia,10"
#$Info1TB.BackColor = "White"
$Info1TB.Text = "Navn:"
$Form.controls.Add($Info1TB) 

$Info2TB = New-Object system.windows.Forms.TextBox
$Info2TB.Text = ""
$Info2TB.AutoSize = $true
$Info2TB.Width = 400
$Info2TB.Height = 10
$Info2TB.ReadOnly = $true
$Info2TB.location = new-object system.drawing.point(16,130)
$Info2TB.Font = "Georgia,10"
#$Info2TB.BackColor = "White"
$Info2TB.Text = "Brugernavn:"
$Form.controls.Add($Info2TB)

$Info3TB = New-Object system.windows.Forms.TextBox
$Info3TB.Text = ""
$Info3TB.AutoSize = $true
$Info3TB.Width = 400
$Info3TB.Height = 10
$Info3TB.ReadOnly = $true
$Info3TB.location = new-object system.drawing.point(16,160)
$Info3TB.Font = "Georgia,10"
#$Info3TB.BackColor = "White"
$Info3TB.Text = "Stilling:"
$Form.controls.Add($Info3TB) 

$Info4TB = New-Object system.windows.Forms.TextBox
$Info4TB.Text = ""
$Info4TB.AutoSize = $true
$Info4TB.Width = 400
$Info4TB.Height = 10
$Info4TB.ReadOnly = $true
$Info4TB.location = new-object system.drawing.point(16,190)
$Info4TB.Font = "Georgia,10"
#$Info4TB.BackColor = "White"
$Info4TB.Text = "Oprettet:"
$Form.controls.Add($Info4TB) 

$ErrorLabel = New-Object system.windows.Forms.Label 
$ErrorLabel.Text = ""
$ErrorLabel.AutoSize = $true
$ErrorLabel.Width = 250
$ErrorLabel.Height = 10
$ErrorLabel.location = new-object system.drawing.point(470,70)
$ErrorLabel.Font = "Georgia,10"
$Form.controls.Add($ErrorLabel)

$UserPictureBox = New-Object system.windows.Forms.PictureBox 
$UserPictureBox.Width = 250
$UserPictureBox.Height = 250
$UserPictureBox.location = new-object system.drawing.point(450,10)
$UserPictureBox.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
#$UserPictureBox.BorderStyle = 'Fixed3D'
$UserPictureBox.Add_Click({Show-OriginalPhoto})
$Form.controls.Add($UserPictureBox)
#endregion ; Gui

#region Functions
Function ADLookupBT_Click(){
    #Check at der er skrevet noget i input feltet
	if (-not ([string]::IsNullOrEmpty($UserInputBox.Text)) -and ($UserInputBox.Text.Length -ge 2 )) {
        Clearfields
        try{$User = Get-ADUser $UserInputBox.Text -Properties *}
        Catch {#Ignorer fejl som der kommer hvis $User ikke er et brugernavn
			}
		if ($User) {
			# User Exists
            LookupUser
            StudizBillede -StudentId $User.SamAccountName
	    } else {
            #TODO fix så man kan skrive fornavn og efternavn
            #håndtering af søgning på alt som navn, selv mellemnavn
            $name = "*" + $UserInputBox.Text + "*"
            $Output = Get-ADUser -Filter {Name -like $name} -Properties SamAccountName,Name,DisplayName,Office,Description
            if ($Output) {
                if ($Output -is [Array]){
                    $Global:bahfail = $null
                    Show-ADUserList $Output
                    foreach ($userInfo in $Output) {
                        if ($userInfo.SamAccountName -eq $bahfail){$User = $userInfo}
                    }
                    if ($User) {
                        LookupUser
                        StudizBillede -StudentId $User.SamAccountName
                    }
                } else {
                    $User = $Output
                    if ($User) {
                        LookupUser
                        StudizBillede -StudentId $User.SamAccountName
                    }
                }
            } else {
                [System.Windows.Forms.MessageBox]::Show("Kunne ikke finde en bruger med navn: " + $User,"Error")
            }         
        }
	}
}

Function StudizBillede(){
    Param([String]$StudentId)
    $response = Invoke-RestMethod -Uri ($BaseUrl + $StudentPhotoUrl + $StudentId) -Headers $headers
    $outputPhotoUrl = $null
    If ($response.message){#No photo has been uploaded
        #write-host $response.message
        if ($response.message -eq "No photo has been uploaded"){
            $UserPictureBox.Image = $null
            $ErrorLabel.Text = $response.message
        } elseif ($response.message -eq "No student match given id"){
            #TODO download pic fra hevucs hjemmeside?
            if (EmployeePicture $StudentId){
                
            } else {
                $UserPictureBox.Image = $null
                $ErrorLabel.Text = $response.message
            }

        } else {
            $UserPictureBox.Image = $null
            $ErrorLabel.Text = $response.message
            write-host $response.message
        }

    } elseif ($response.student_standard_photo_url -eq "Version not available"){
        $outputPhotoUrl = $response.student_original_photo_url
        #Write-host Original Photo
    } else {
        $outputPhotoUrl = $response.student_standard_photo_url

        #til håndtering hvis man klikker på billedet for at få et stort billede
        $Global:OriPhoto = $response.student_original_photo_url
    }
    $Picture = $null

    if ($outputPhotoUrl){
    #Hvis der ikke er en url, så lad være med at prøve at download et billede
    $Picture = Invoke-WebRequest -Uri $outputPhotoUrl -Headers $headers -UseBasicParsing | Select-Object -ExpandProperty Content
        if ($Picture) {
            # Convert image data to bitmap
            $stream = New-Object System.IO.MemoryStream
            $stream.Write($Picture, 0, $Picture.Length)
            $bitmap = New-Object System.Drawing.Bitmap($stream)
            $UserPictureBox.Image = $bitmap
        }
    }
    
}

function Show-ADUserList {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [System.Collections.ArrayList]$InputObject
    )
        $popform = New-Object System.Windows.Forms.Form
        $popform.Text = "Vælg bruger"
        $popform.Width = 600
        $popform.Height = 300
        #$form.AutoSize = $true
        $popform.AutoSizeMode = 'GrowAndShrink'
        $popform.AutoScaleMode = 'Dpi'
        $popform.AutoScaleDimensions = '96, 96'
        $popform.Padding = '10, 10, 10, 10'
        
        $popform.Icon = $icon
        $listView = New-Object System.Windows.Forms.ListView
        $listView.Dock = [System.Windows.Forms.DockStyle]::Fill
        $listView.View = [System.Windows.Forms.View]::Details
        $listView.FullRowSelect = $true
        $listView.MultiSelect = $false
        $listView.Font = "Georgia,10"
        $listView.Columns.AddRange(@(
            (New-Object System.Windows.Forms.ColumnHeader -Property @{Text = "Brugernavn"; Width = -2}),
            (New-Object System.Windows.Forms.ColumnHeader -Property @{Text = "Navn"; Width = -2}),
            (New-Object System.Windows.Forms.ColumnHeader -Property @{Text = "Type"; Width = -2}),
            (New-Object System.Windows.Forms.ColumnHeader -Property @{Text = "Beskrivelse"; Width = -2})
        ))
        $popform.Controls.Add($listView)
        
        $okButton = New-Object System.Windows.Forms.Button
        $okButton.Text = "OK"
        $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $okButton.Dock = [System.Windows.Forms.DockStyle]::Bottom
        #TODO fix denne grimme hack for at få output fra funktionen
        $okButton.Add_Click({$Global:bahfail = $listview.SelectedItems[0].SubItems[0].Text})
        $popform.AcceptButton = $okButton
        $popform.Controls.Add($okButton)
        
        #$listView.Items.Clear()
        foreach ($user in $InputObject) {
            $item = New-Object System.Windows.Forms.ListViewItem($user.SamAccountName)
            $item.SubItems.Add($user.DisplayName)
            if ($user.Office){$item.SubItems.Add($user.Office) | Out-Null}else{$item.SubItems.Add("") | Out-Null}
            if ($user.Description){$item.SubItems.Add($user.Description) | Out-Null}else{$item.SubItems.Add("") | Out-Null}
            $listView.Items.Add($item) | Out-Null
        }

        #$popform.Add_KeyDown({$_.SuppressKeyPress = $True})
        $popform.ShowDialog() | Out-Null
}

Function Show-OriginalPhoto{
    param (
        $DownloadURL = $OriPhoto
    )
    if ($DownloadURL){
        $Picture = Invoke-WebRequest -Uri $DownloadURL -Headers $headers -UseBasicParsing | Select-Object -ExpandProperty Content
        if ($Picture) {
            # Convert image data to bitmap
            $stream = New-Object System.IO.MemoryStream
            $stream.Write($Picture, 0, $Picture.Length)
            $bitmap = New-Object System.Drawing.Bitmap($stream)
            #$UserPictureBox.Image = $bitmap
            #ShowPicture -imageData $bitmap
            if ($bitmap) {
                $pictureBox = New-Object System.Windows.Forms.PictureBox
                $pictureBox.Width = 500
                $pictureBox.Height = 500
                $pictureBox.Image = $bitmap
                $pictureBox.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
                #Beholder billedes ratio, men strækker billedet til størelsen af picturebox
                $pictureBox.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
                $form = New-Object System.Windows.Forms.Form
                $form.Controls.Add($pictureBox)
                $Form.Icon = $icon
                $form.ShowDialog() | Out-Null
            }
        }
    }
}

Function Clearfields(){
$GroupListBox.Items.Clear()
$Info1TB.Text = "Navn:"
$Info2TB.Text = "Brugernavn:"
$Info3TB.Text = "Stilling:"
$Info4TB.Text = "Oprettet:"
$ErrorLabel.Text = ""
$UserPictureBox.Image = $NoUserImage
#$Info1TB.BackColor = "White"
}

Function LookupUser(){
            #Gør navne feltet rødt hvis brugeren er deaktieret i ad'et
            #if ($User.Enabled -eq "False") {$Info1TB.BackColor = 'Red'}
			$Info1TB.Text = "Navn: " + $User.Name
            $Info2TB.Text = "Brugernavn: " + $User.SamAccountName
			$Info3TB.Text = "Stilling: " + $User.Office
            $Info4TB.Text = "Oprettet: " + $User.Description
            $Groups = Get-ADPrincipalGroupMembership $User.SamAccountName
            Foreach ($Name in $Groups){
                if ($Name.Name.StartsWith("Fag",'CurrentCultureIgnoreCase')){ $GroupListBox.Items.Add($Name.Name)}
            }    
}

Function EmployeePicture {
    Param(
    [String]$username
    )
    #checker for om der er tal i brugernavnet, da ansatte ikke har tal i deres brugernavn
    if ($username -notmatch '\d') {
        try{$Picture = Invoke-WebRequest -Uri ("https://herninghfogvuc.dk/wp-content/uploads/2023/08/$username.jpg") -UseBasicParsing | Select-Object -ExpandProperty Content}
        catch{<#Går i fejl der ikke er et billede på hjemmesiden med kun brugerens initialer#>}
        if ($Picture) {
            # Convert image data to bitmap
            $stream = New-Object System.IO.MemoryStream
            $stream.Write($Picture, 0, $Picture.Length)
            $bitmap = New-Object System.Drawing.Bitmap($stream)
            $UserPictureBox.Image = $bitmap
            return $true
        } else {
                $UserPictureBox.Image = $null
                $ErrorLabel.Text = "Intet billede kaldt $username"
            return $true
        }
    } else {
        return $false
    }
}
#endregion Functions

$Base64NoUser = "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
AUUUUAf/2Q=="

# Convert the base64 string to a byte array
$bytes = [System.Convert]::FromBase64String($Base64NoUser)

# Create an image object from the byte array
$stream = New-Object System.IO.MemoryStream($bytes, 0, $bytes.Length)
$NoUserImage = [System.Drawing.Image]::FromStream($stream)
$UserPictureBox.Image = $NoUserImage

[void]$Form.ShowDialog() 
$Form.Dispose() 
