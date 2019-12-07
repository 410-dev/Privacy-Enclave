//
//  ViewController.swift
//  Privacy Enclave
//
//  Created by Hoyoun Song on 2019/11/27.
//  Copyright © 2019 Hoyoun Song. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    // Outlet Objects
    @IBOutlet weak var Outlet_VersionLabel: NSTextField!
    @IBOutlet weak var Outlet_Console: NSScrollView!
    @IBOutlet weak var Outlet_StatMessage: NSTextField!
    @IBOutlet weak var Outlet_Spinner: NSProgressIndicator!
    @IBOutlet weak var Outlet_LoginPassword: NSSecureTextField!
    @IBOutlet weak var Outlet_EnclavePassword: NSSecureTextField!
    @IBOutlet weak var Outlet_HiddenuserName: NSTextField!
    @IBOutlet weak var Outlet_HiddenuserPassword: NSSecureTextField!
    @IBOutlet weak var Outlet_ActionButton: NSButton!
    @IBOutlet weak var Outlet_ControlSegment: NSSegmentedControl!
    
    
    // Global Constants
    let version = "Prerelease 2"
    let nemesisAPIPath = "/usr/local/nemesis.shapi/commandlines/"
    let libpePath = "/usr/local/libprivacyenclave"
    let peapiPath = "/usr/local/privacyenclave.shapi/commandlines/"
    let enclavePath = "/usr/local/libprivacyenclave/enclave.dmg"
    let realEnclavePath = "/usr/local/libprivacyenclave/enclave.dmg.sparseimage"
    let cmd = "/usr/local/bin/privacyenclave/"
    let System: SystemLevelCompatibilityLayer = SystemLevelCompatibilityLayer()
    let Graphics: GraphicComponents = GraphicComponents()
    let BundleResources = Bundle.main.resourcePath ?? "/Applications/Privacy Enclave Launcher.app/Contents/Resources/Privacy Enclave.app/Contents/Resources"
    
    
    // Global Variables
    var missingResources = ""
    var buttonEnabled = true
    var doesEnclaveGenerated = false
    var password = ""
    var isKIS = true
    
    func startup() {
        writeLog("Init", "")
        writeLog("Version: " + version, "")
        Outlet_VersionLabel.stringValue = version
        Outlet_Spinner.isHidden = true
        Outlet_Spinner.stopAnimation("")
        writeLog("Privacy Enclave Graphic Utility", "")
        updateControlStrip()
        writeLog("Checking system state...", "")
        isKIS = isKISImage()
        writeLog("Ready.", "")
    }
    
    func updateControlStrip() {
        if System.doesTheFileExist(at: realEnclavePath) && System.doesTheFileExist(at: "/usr/local/mpkglib/db/org.hysong.privacyenclavecommandline"){
            doesEnclaveGenerated = true
            writeLog("Enclave exists.", "")
            Outlet_ControlSegment.setEnabled(false, forSegment: 3)
            Outlet_ControlSegment.setSelected(false, forSegment: 3)
            if System.doesTheFileExist(at: "/Volumes/Enclave") {
                Outlet_ControlSegment.setEnabled(false, forSegment: 0)
                Outlet_ControlSegment.setEnabled(true, forSegment: 1)
                Outlet_ControlSegment.setEnabled(true, forSegment: 2)
                Outlet_ControlSegment.setSelected(true, forSegment: 1)
            }else{
                Outlet_ControlSegment.setEnabled(true, forSegment: 0)
                Outlet_ControlSegment.setEnabled(false, forSegment: 1)
                Outlet_ControlSegment.setEnabled(false, forSegment: 2)
                Outlet_ControlSegment.setSelected(true, forSegment: 0)
            }
        }else{
            writeLog("Enclave does not exist.", "-")
            Outlet_ControlSegment.setEnabled(false, forSegment: 0)
            Outlet_ControlSegment.setEnabled(false, forSegment: 1)
            Outlet_ControlSegment.setEnabled(false, forSegment: 2)
            Outlet_ControlSegment.setEnabled(true, forSegment: 3)
            Outlet_ControlSegment.setSelected(true, forSegment: 3)
        }
    }
    
    func checkPermission() {
        let pass = Outlet_LoginPassword.stringValue
        writeLog("Checking permission...", "")
        System.executeShellScriptWithRootPrivilages(pass: pass, "touch#/var/rwchk")
        if !System.doesTheFileExist(at: "/var/rwchk") {
            writeLog("Permission denied!", "!")
            Graphics.messageBox_errorMessage(title: "No Permission", contents: "Please use the official launcher. The tool cannot run several utilites.")
            exit(1)
        }else{
            System.executeShellScriptWithRootPrivilages(pass: pass, "rm#-f#/var/rwchk")
            writeLog("Permission passed.", "")
            password = pass
        }
    }
    
    func writeLog(_ value: String, _ sign: String) {
        var showSign = sign
        if sign.elementsEqual("") {
            showSign = "*"
        }
        Outlet_Console.documentView!.insertText("[" + showSign + "] " + value.replacingOccurrences(of: "Password:", with: "") + "\n")
        print("[" + showSign + "] " + value.replacingOccurrences(of: "Password:", with: ""))
    }
    
    func updateStatus(status: String) {
        Outlet_StatMessage.stringValue = status
        writeLog("Status: " + status, "")
    }
    
    @IBAction func StartTask(_ sender: Any) {
        if buttonEnabled {
            if !Outlet_EnclavePassword.stringValue.elementsEqual("") && !Outlet_LoginPassword.stringValue.elementsEqual(""){
                task()
            }else{
                Graphics.messageBox_errorMessage(title: "Passwords Empty", contents: "The first two password fields are empty. Please fill tem first.")
            }
        }else{
            writeLog("Ignored button input.", "-")
        }
    }
    
    
    func nemesis(enabledToggle: Bool) {
        if enabledToggle {
            writeLog("Renaming snapshot dump...", "")
            updateStatus(status: "Rename Snapshot Dump")
            if System.executeShellScriptWithRootPrivilages(pass: password, "mv#/Library/Application Support/LanSchool#/Library/Application Support/Nemesis_protected_LanSchool") == 0 {
                writeLog("Successfully renamed snapshot dump.", "")
            }else{
                writeLog("Snapshot dump renaming failed. Non-zero exit code.", "!")
                Graphics.messageBox_errorMessage(title: "Snapshot Dump Rename Failed", contents: "Failed renaming snapshot dump. Failed stopping LanSchool.")
                exit(-9)
            }
            writeLog("Manipulating Launchctl...", "")
            updateStatus(status: "Launchctl Manipulation")
            if System.executeShellScriptWithRootPrivilages(pass: password, nemesisAPIPath + "launchctlmgr#unload") == 0 {
                writeLog("Successfully manipulated launchctl.", "")
            }else{
                writeLog("Launchctl manipulation failed. Non-zero exit code.", "!")
                Graphics.messageBox_errorMessage(title: "Launchctl Modification Failed", contents: "Failed unloading LSD from launchctl.")
                exit(-9)
            }
            writeLog("Killing LSTask...", "")
            updateStatus(status: "Kill LSTask")
            if System.executeShellScriptWithRootPrivilages(pass: password, nemesisAPIPath + "killtask#-9") == 0 {
                writeLog("Successfully killed lstask.", "")
            }else{
                writeLog("LSTask kill failed. Non-zero exit code.", "!")
                Graphics.messageBox_errorMessage(title: "Task Kill Failed", contents: "Failed killing LSTasks.")
                exit(-9)
            }
        }else{
            writeLog("Renaming snapshot dump...", "")
            updateStatus(status: "Rename Snapshot Dump")
            if System.executeShellScriptWithRootPrivilages(pass: password, "mv#/Library/Application Support/Nemesis_protected_LanSchool#/Library/Application Support/LanSchool") == 0 {
                writeLog("Successfully renamed snapshot dump.", "")
            }else{
                writeLog("Snapshot dump renaming failed. Non-zero exit code.", "!")
                Graphics.messageBox_errorMessage(title: "Snapshot Dump Rename Failed", contents: "Failed renaming snapshot dump. Failed restoring LanSchool.")
                exit(-9)
            }
            writeLog("Manipulating Launchctl...", "")
            updateStatus(status: "Launchctl Manipulation")
            if System.executeShellScriptWithRootPrivilages(pass: password,nemesisAPIPath + "launchctlmgr#load") == 0 {
                writeLog("Successfully manipulated launchctl.", "")
            }else{
                writeLog("Launchctl manipulation failed. Non-zero exit code.", "!")
                Graphics.messageBox_errorMessage(title: "Launchctl Modification Failed", contents: "Failed injecting LSD to launchctl.")
                exit(-9)
            }
            writeLog("Starting LSTask...", "")
            updateStatus(status: "Start LSTask")
            System.executeShellScriptWithRootPrivilages(pass: password, nemesisAPIPath + "execLS")
            System.executeShellScriptWithRootPrivilages(pass: password, nemesisAPIPath + "execST")
        }
    }
    
    func create() -> Int32{
        if !Outlet_EnclavePassword.stringValue.elementsEqual(""){
            return System.executeShellScriptWithRootPrivilages(pass: password, peapiPath + "createvfs#" + enclavePath + "#Enclave#10240g#APFS#" + Outlet_EnclavePassword.stringValue)
        }else{
            let _ = Graphics.messageBox_errorMessage(title: "Empty Password", contents: "Enclave password field is empty.")
            return 1
        }
    }
    
    func delete() -> Int32 {
        if unmount() != 0 {
            writeLog("Detach failed.", "!")
            writeLog("Resource busy!", "!")
            Graphics.messageBox_errorMessage(title: "Resource Busy", contents: "Unable to deactivate the enclave, perhaps an application is using files in the enclave?")
            return 1
        }else{
            if !Outlet_EnclavePassword.stringValue.elementsEqual("") && mount() == 0{
                if unmount() != 0 {
                    writeLog("Detach failed.", "!")
                    writeLog("Resource busy!", "!")
                    Graphics.messageBox_errorMessage(title: "Resource Busy", contents: "Unable to deactivate the enclave, perhaps an application is using files in the enclave?")
                    return 1
                }else{
                    System.executeShellScriptWithRootPrivilages(pass: password, "rm#-f#" + realEnclavePath)
                    if !System.doesTheFileExist(at: realEnclavePath) {
                        return 0
                    }else{
                        return 1
                    }
                }
            }else{
                let _ = Graphics.messageBox_errorMessage(title: "Authentication Failed", contents: "Permission denied to remove the privacy enclave.")
                return 1
            }
        }
    }
    
    func mount() -> Int32 {
        if !Outlet_EnclavePassword.stringValue.elementsEqual(""){
            return System.executeShellScriptWithRootPrivilages(pass: password, peapiPath + "mountvfs#" + Outlet_EnclavePassword.stringValue + "#" + realEnclavePath)
        }else{
            let _ = Graphics.messageBox_errorMessage(title: "Empty Password", contents: "Enclave password field is empty.")
            return 1
        }
    }
    
    func unmount() -> Int32 {
        if !Outlet_EnclavePassword.stringValue.elementsEqual("") && mount() == 0{
            return System.executeShellScriptWithRootPrivilages(pass: password, "hdiutil#detach#/Volumes/Enclave#-force")
        }else{
            let _ = Graphics.messageBox_errorMessage(title: "Empty Password", contents: "Enclave password field is empty.")
            return 1
        }
    }
    
    func task() {
        buttonEnabled = false
        Outlet_Spinner.isHidden = false
        Outlet_Spinner.startAnimation("")
        Outlet_LoginPassword.isEnabled = false
        Outlet_EnclavePassword.isEnabled = false
        Outlet_HiddenuserName.isEnabled = false
        Outlet_HiddenuserPassword.isEnabled = false
        Outlet_ActionButton.image = NSImage(imageLiteralResourceName: "working.png")
        writeLog("Button Pressed; Starting tasks!", "")
        updateStatus(status: "Check Privilages")
        checkPermission()
        rsMgr()
        let SelectedOption = Outlet_ControlSegment.selectedSegment
        if SelectedOption == 0 && isKIS {
            updateStatus(status: "Disable LanSchool")
            writeLog("Disabling LanSchool for the moment...", "")
            nemesis(enabledToggle: isKIS)
        }else{
            writeLog("LanSchool is not detected.", "")
        }
        updateStatus(status: "Run Assigned Task")
        writeLog("Running assigned task...", "")
        if SelectedOption == 0 {
            writeLog("Unlocking enclave...", "")
            if mount() == 0 {
                Graphics.messageBox_dialogue(title: "Process Complete", contents: "Successfully unlocked Privacy Enclave.")
                Outlet_Spinner.isHidden = true
                Outlet_ActionButton.image = NSImage(imageLiteralResourceName: "unlocked.png")
                buttonEnabled = true
                writeLog("The process was successful.", "")
                Outlet_ActionButton.image = NSImage(imageLiteralResourceName: "ready.png")
            }else{
                Graphics.messageBox_errorMessage(title: "Process Failed", contents: "Failed unlocking Privacy Enclave. Please check terminal log.")
                Outlet_Spinner.isHidden = true
                buttonEnabled = true
                updateStatus(status: "Failed")
                writeLog("The process was unsuccessful.", "-")
                Outlet_ActionButton.image = NSImage(imageLiteralResourceName: "ready.png")
            }
        }else if SelectedOption == 1 {
            writeLog("Locking enclave...", "")
            if unmount() == 0 {
                Graphics.messageBox_dialogue(title: "Process Complete", contents: "Successfully locked Privacy Enclave.")
                Outlet_Spinner.isHidden = true
                Outlet_ActionButton.image = NSImage(imageLiteralResourceName: "locked.png")
                buttonEnabled = true
                writeLog("The process was successful.", "")
           }else{
                Graphics.messageBox_errorMessage(title: "Process Failed", contents: "Failed unlocking Privacy Enclave. Please check terminal log.")
                Outlet_Spinner.isHidden = true
                buttonEnabled = true
                updateStatus(status: "Failed")
                writeLog("The process was unsuccessful.", "-")
                Outlet_ActionButton.image = NSImage(imageLiteralResourceName: "ready.png")
           }
        }else if SelectedOption == 2 {
            writeLog("Erasing enclave...", "")
            updateStatus(status: "Erase Enclave")
            Graphics.messageBox_dialogue(title: "Backup Enclave", contents: "Please make sure you backed up the contents of the privacy enclave.")
            if delete() == 0 {
                Graphics.messageBox_dialogue(title: "Process Complete", contents: "Successfully unlocked Privacy Enclave.")
                Outlet_Spinner.isHidden = true
                buttonEnabled = true
                writeLog("The process was successful.", "")
                Outlet_ActionButton.image = NSImage(imageLiteralResourceName: "ready.png")
           }else{
                Graphics.messageBox_errorMessage(title: "Process Failed", contents: "Failed unlocking Privacy Enclave. Please check terminal log.")
                Outlet_Spinner.isHidden = true
                buttonEnabled = true
                updateStatus(status: "Failed")
                writeLog("The process was unsuccessful.", "-")
                Outlet_ActionButton.image = NSImage(imageLiteralResourceName: "ready.png")
           }
        }else if SelectedOption == 3 {
            writeLog("Creating enclave...", "")
            updateStatus(status: "Create Enclave")
            if create() == 0 {
                Graphics.messageBox_dialogue(title: "Process Complete", contents: "Successfully created Privacy Enclave.")
                Outlet_Spinner.isHidden = true
                buttonEnabled = true
                writeLog("The process was successful.", "")
            }else{
                Graphics.messageBox_errorMessage(title: "Process Failed", contents: "Failed creating Privacy Enclave. Please check terminal log.")
                Outlet_Spinner.isHidden = true
                buttonEnabled = true
                updateStatus(status: "Failed")
                writeLog("The process was unsuccessful.", "-")
                Outlet_ActionButton.image = NSImage(imageLiteralResourceName: "ready.png")
            }
        }else{
            Graphics.messageBox_errorMessage(title: "Option not selected", contents: "No such option is available.")
        }
        if (SelectedOption == 0 || SelectedOption == 2) && isKIS {
            updateStatus(status: "Enable LanSchool")
            writeLog("Enabling LanSchool again...", "")
            nemesis(enabledToggle: false)
        }
        if !Outlet_StatMessage.stringValue.elementsEqual("Failed") {
            updateStatus(status: "Done")
        }
        updateControlStrip()
        buttonEnabled = true
        Outlet_Spinner.isHidden = true
        Outlet_LoginPassword.isEnabled = true
        Outlet_EnclavePassword.isEnabled = true
        Outlet_HiddenuserName.isEnabled = true
        Outlet_HiddenuserPassword.isEnabled = true
        writeLog("Task all complete.", "")
    }
    
    func rsMgr() {
        checkResources()
        if !missingResources.elementsEqual("") {
            writeLog("Installing missing resources...", "")
            updateStatus(status: "Installing")
            let listOfMissingResources = missingResources.components(separatedBy: ";")
            var loopcount = 0
            while listOfMissingResources.count - 1 > loopcount {
                if listOfMissingResources[loopcount].elementsEqual("mpkg") {
                    writeLog("Extracting mpkg package manager...", "")
                    System.executeShellScriptWithRootPrivilages(pass: password, BundleResources + "/mpkg-live.sh#-i#" + BundleResources + "/CorePackages/mpkg.mpack")
                    writeLog("Extracting net package manager...", "")
                    System.executeShellScriptWithRootPrivilages(pass: password, BundleResources + "/mpkg-live.sh#-i#" + BundleResources + "/CorePackages/net.mpack")
                }else if listOfMissingResources[loopcount].elementsEqual("") {
                    writeLog("Skipped empty package selection.", "")
                }else{
                    writeLog("Installing " + listOfMissingResources[loopcount] + " locally...", "")
                    if System.executeShellScriptWithRootPrivilages(pass: password, "/usr/local/bin/mpkg#--install#" + BundleResources + "/CorePackages/" + listOfMissingResources[loopcount] + ".mpack") == 0 {
                        writeLog("Sub-process /usr/local/mpkglib/binary/mpkg-install returned exit code 0.", "")
                    }else{
                        writeLog("Sub-process /usr/local/mpkglib/binary/mpkg-install returned non-zero exit code.", "-")
                    }
                }
                loopcount += 1
            }
            checkResources()
            if !missingResources.elementsEqual("") {
                Graphics.messageBox_errorMessage(title: "Still missing resources", contents: "")
            }
        }
    }
    
    func isKISImage() -> Bool {
        if System.doesTheFileExist(at: "/Library/Application Support/LanSchool") {
            return true
        }else{
            return false
        }
    }
    
    func checkResources() {
        writeLog("Checking resources...", "")
        updateStatus(status: "Checking Resources")
        let mpkgdb = "/usr/local/mpkglib/db/"
        let mpkg8 = mpkgdb + "mpkg8"
        let nemesis = mpkgdb + "org.hysong.nemesis"
        let nemesisapi = mpkgdb + "org.hysong.nemesisapi"
        let libprivacyenclave = mpkgdb + "org.hysong.libprivacyenclave"
        let commandlines = mpkgdb + "org.hysong.privacyenclavecommandline"
        let vstect = mpkgdb + "org.hysong.verstect"
        let commoncrypto = mpkgdb + "org.hysong.commoncrypto"
        let libusersupport = mpkgdb + "libusersupport"
        missingResources = ""
        writeLog("Checking: mpkg", "")
        if System.doesTheFileExist(at: "/usr/local/bin/mpkg"){
            writeLog("Verified: mpkg", "")
        }else{
            writeLog("Missing: mpkg", "-")
            missingResources = "mpkg;"
        }
        writeLog("Checking: mpkg8", "")
        if System.doesTheFileExist(at: mpkg8){
            writeLog("Verified: mpkg8", "")
        }else{
            writeLog("Missing: mpkg8", "-")
            missingResources = missingResources + "mpkg8_profile;"
        }
        writeLog("Checking: nemesis", "")
        if System.doesTheFileExist(at: nemesis){
            writeLog("Verified: nemesis", "")
        }else{
            writeLog("Missing: nemesis", "-")
            missingResources = missingResources + "nemesis;"
        }
        writeLog("Checking: nemesisapi", "")
        if System.doesTheFileExist(at: nemesisapi){
            writeLog("Verified: nemesisapi", "")
        }else{
            writeLog("Missing: nemesisapi", "-")
            missingResources = missingResources + "nemesisapi;"
        }
        writeLog("Checking: commoncrypto", "")
        if System.doesTheFileExist(at: commoncrypto){
            writeLog("Verified: commoncrypto", "")
        }else{
            writeLog("Missing: commoncrypto", "-")
            missingResources = missingResources + "commoncrypto;"
        }
        writeLog("Checking: libprivacyenclave", "")
        if System.doesTheFileExist(at: libprivacyenclave){
            writeLog("Verified: libprivacyenclave", "")
        }else{
            writeLog("Missing: libprivacyenclave", "-")
            missingResources = missingResources + "libprivacyenclave;"
        }
        writeLog("Checking: verstect", "")
        if System.doesTheFileExist(at: vstect){
            writeLog("Verified: verstect", "")
        }else{
            writeLog("Missing: verstect", "-")
            missingResources = missingResources + "verstect;"
        }
        writeLog("Checking: libusersupport", "")
        if System.doesTheFileExist(at: libusersupport){
            writeLog("Verified: libusersupport", "")
        }else{
            writeLog("Missing: libusersupport", "-")
            missingResources = missingResources + "libusersupport;"
        }
        writeLog("Checking: commandlines", "")
        if System.doesTheFileExist(at: commandlines){
            writeLog("Verified: commandlines", "")
        }else{
            writeLog("Missing: commandlines", "-")
            missingResources = missingResources + "commandlines;"
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        startup()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

