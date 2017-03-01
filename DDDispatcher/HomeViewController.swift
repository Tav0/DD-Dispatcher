//
//  LoginViewController.swift
//  DDDispatcher
//
//  Created by macbookair11 on 2/18/17.
//  Copyright © 2017 DD Dispatcher. All rights reserved.
//

import UIKit
import Firebase
import FBSDKLoginKit
import GoogleSignIn
import TextFieldEffects

/*
    TODOS: UI -   constraints
                  icons next to Ouath buttons
                  logo
                  better spacing
           Logic- confirm account uniqueness
                  provide error handling (incorrect password, already used email, etc.)
                  connect to firebase for email users
                  infoSegue must also be done for Twitter users
                  grab personal user data from Google
                  store personal user data to DB
 
 */
class HomeScreenViewController: UIViewController, GIDSignInUIDelegate, GIDSignInDelegate, UITextFieldDelegate {
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var facebookButton: UIButton!
    @IBOutlet weak var googleButton: UIButton!
    @IBOutlet weak var mailView: UIView!
    @IBOutlet weak var mailButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //setup
        emailTextField.keyboardType = .emailAddress
        self.emailTextField.delegate = self
        self.passwordTextField.delegate = self
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(HomeScreenViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        //UI
        setTextField(textField: emailTextField)
        setTextField(textField: passwordTextField)
        customizeLoginButton()
        
        //OAuth
        setupFacebookButton()
        setupGoogleButton()
        
    }
//================== UI Setup =================================
    
    
    func setTextField(textField: UITextField) {
        textField.borderStyle = .none
        textField.layer.backgroundColor = UIColor.white.cgColor
        textField.layer.masksToBounds = false
        textField.layer.shadowColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 1).cgColor
        textField.layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
        textField.layer.shadowOpacity = 1.0
        textField.layer.shadowRadius = 0.0
        
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.textColor = UIColor.black
        textField.layer.shadowColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 1).cgColor
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.textColor = UIColor.lightGray
        textField.layer.borderColor = UIColor(red: 126/255, green: 127/255, blue: 137/255, alpha: 1).cgColor
    }
    
    func customizeLoginButton() {
        loginButton.layer.cornerRadius = 15
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
//================== End of UI Setup ===========================
//================== OAuth Setup ===============================
    
    // Facebook button setup
    fileprivate func setupFacebookButton() {
        facebookButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 250)
        facebookButton.setTitle("Facebook", for: .normal)
        if facebookButton.isHighlighted {
            facebookButton.backgroundColor = UIColor.black
        }
    }
    
    @IBAction func handleFacebookLogin(_ sender: Any) {
        FBSDKLoginManager().logIn(withReadPermissions: ["email", "public_profile"], from: self) { (result, error) in
            if let err = error {
                print("Failed to login to Firebase with Facebook: ", err)
                return
            }
            self.connectFacebookToFirebase()
        }
    }
    
    func connectFacebookToFirebase() {
        let accessToken = FBSDKAccessToken.current()
        guard let accessTokenString = accessToken?.tokenString else { return }
        let credentials = FIRFacebookAuthProvider.credential(withAccessToken: accessTokenString)
        FIRAuth.auth()?.signIn(with: credentials, completion: { (user, error) in
            if let err = error {
                print("Something went wrong with our FB user: ", err )
                return
            }
            print("Successfully logged into Firebase with Facebook: ", user ?? "")
            DispatchQueue.main.async(execute: {
                self.performSegue(withIdentifier: "hubSegue", sender: self)
            })
           
        })
        
        FBSDKGraphRequest(graphPath: "/me", parameters: ["fields": "id, name, email"]).start { (connection, result, error) in
            if let err = error {
                print("Failed to start graph request:", err)
                    return
            }
            //TODO:This is where we can store user's personal data from Facebook to Firebase
            print(result ?? "")
        }
    }
    
    // End of Facebook button setup
    
    //Google button setup
    fileprivate func setupGoogleButton() {
        googleButton.setTitle("Google", for: .normal)
        googleButton.setTitleColor(.white, for: .normal)
        googleButton.addTarget(self, action: #selector(handleGoogleLogin), for: .touchUpInside)
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
    }
    
    func handleGoogleLogin() {
        GIDSignIn.sharedInstance().signIn()
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let err = error {
            print("Failed to login via Google: ", err)
            return
        }
        
        print("Successfully logged into Google", user)
        /* We can store user information to Firebase here.. 
            user.profile.name
            user.profile.email
         
         */
        
        guard let idToken = user.authentication.idToken else { return }
        guard let accessToken = user.authentication.accessToken else { return }
        let credentials = FIRGoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        
        FIRAuth.auth()?.signIn(with: credentials, completion: { (user, error) in
            if let err = error {
                print("Failed to log into Firebase with Google: ", err)
                return
            }
            
            guard let uid = user?.uid else { return }
            print("Successfully logged into Firebase with Google: ", uid)
            DispatchQueue.main.async(execute: {
                self.performSegue(withIdentifier: "hubSegue", sender: self)
            })
        })
    }

    // End of Google button setup
    
    @IBAction func beginMailTransition(_ sender: Any) {
       
    }
    
    
    
    
    
    @IBAction func loginOnClick(_ sender: Any) {
        guard let inputEmail = emailTextField.text else { return }
        guard let inputPassword = passwordTextField.text else { return }
        if isValidPassword(inputPassword: inputPassword) {
            FIRAuth.auth()!.signIn(withEmail: inputEmail, password: inputPassword, completion: { (user, error) in
                if error != nil  {
                    if let errCode = FIRAuthErrorCode(rawValue: error!._code) {
                        switch errCode {
                        case .errorCodeInvalidEmail:
                            print("invalid email")
                        case .errorCodeEmailAlreadyInUse:
                            print("in use")
                        case .errorCodeUserNotFound:
                            FIRAuth.auth()!.createUser(withEmail: inputEmail, password: inputPassword, completion: { (user, error) in
                                if let err = error {
                                    print("Error with email user", err)
                                }
                                print("Created user")
                            })
                        default:
                            print("Create User Error: \(error!)")
                        }
                    }
                    return
                }
            })
            segueTo()
        }
        
    }
    
    func isValidPassword(inputPassword :String) -> Bool {
        return inputPassword.characters.count > 6
    }
    
    
    func segueTo () {
        //TODO: We must make a backendquery here. If the user is logging in for the first time and is using an email, or Twitter (check on this), then we need their name. Otherwise, continue on. 
        let newEmailUser = false
        
        if newEmailUser {
            performSegue(withIdentifier: "infoSegue", sender: self)
        } else {
            performSegue(withIdentifier: "hubSegue", sender: self)
        }
    }
    
    
    
}
