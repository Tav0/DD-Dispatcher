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
import TwitterKit

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
class HomeScreenViewController: UIViewController, GIDSignInUIDelegate, GIDSignInDelegate {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var facebookButton: UIButton!
    @IBOutlet weak var googleButton: UIButton!
    @IBOutlet weak var twitterButton: UIButton!
    var uid = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //UI
        setTextField(textField: emailTextField)
        setTextField(textField: passwordTextField)
        customizeLoginButton()
        
        //OAuth
        setupFacebookButton()
        setupGoogleButton()
        setupTwitterButton()
        
    }
//================== UI Setup =================================
    func setTextField(textField: UITextField) {
        let border = CALayer()
        let width = CGFloat(2.0)
        border.borderColor = UIColor(red: 240/255, green: 125/255, blue: 101/255, alpha: 1).cgColor
        border.frame = CGRect(x: 0, y: textField.frame.size.height - width, width:  textField.frame.size.width, height: textField.frame.size.height)
        border.borderWidth = width
        textField.layer.addSublayer(border)
        textField.layer.masksToBounds = true
    }
    
    func customizeLoginButton() {
        loginButton.layer.backgroundColor = UIColor(red: 240/255, green: 125/255, blue: 101/255, alpha: 1).cgColor
        loginButton.setTitleColor(UIColor(red: 250/255, green: 244/255, blue: 227/255, alpha: 1), for: .normal)
        loginButton.layer.cornerRadius = 15
    }
//================== End of UI Setup ===========================
    
//================== OAuth Setup ===============================
    
    // Facebook button setup
    fileprivate func setupFacebookButton() {
        facebookButton.backgroundColor = .blue
        //This is temporary. Better to use constraints
        
        facebookButton.setTitle("Facebook", for: .normal)
        facebookButton.layer.backgroundColor = UIColor(red: 54/255, green: 97/255, blue: 150/255, alpha: 1).cgColor
        facebookButton.setTitleColor(.white, for: .normal)
        facebookButton.layer.cornerRadius = 15
        
        
        facebookButton.addTarget(self, action: #selector(handleFacebookLogin), for: .touchUpInside)
    }
    
    func handleFacebookLogin() {
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
            self.uid = (user?.uid)!
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
        googleButton.layer.backgroundColor = UIColor(red: 217/255, green: 55/255, blue: 44/255, alpha: 1).cgColor
        googleButton.setTitleColor(.white, for: .normal)
        googleButton.layer.cornerRadius = 15
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
            self.uid = uid
            DispatchQueue.main.async(execute: {
                self.performSegue(withIdentifier: "hubSegue", sender: self)
            })
        })
    }

    // End of Google button setup
    
    //Twitter button setup
    fileprivate func setupTwitterButton() {
        twitterButton.setTitle("Twitter", for: .normal)
        twitterButton.layer.backgroundColor = UIColor(red: 29/255, green: 161/255, blue: 244/255, alpha: 1).cgColor
        twitterButton.setTitleColor(.white, for: .normal)
        twitterButton.layer.cornerRadius = 15
        twitterButton.addTarget(self, action: #selector(handleTwitterLogin), for: .touchUpInside)
    }
    func handleTwitterLogin() {
        Twitter.sharedInstance().logIn { (session, error) in
            if let err = error {
                print("Failed to login via Twitter: ", err)
                return
            }
            print("Successfully logged into Twitter")
            
            
            guard let token = session?.authToken else { return }
            guard let secret = session?.authTokenSecret else { return }
            let credentials = FIRTwitterAuthProvider.credential(withToken: token, secret: secret)
            
            FIRAuth.auth()?.signIn(with: credentials, completion: { (user, error) in
                
                if let err = error {
                    print("Failed to login to Firebase with Twitter: ", err)
                    return
                }
                
                print("Successfully logged into Firebase with Twitter: ", user?.uid ?? "")
                self.uid = (user?.uid)!
                DispatchQueue.main.async(execute: {
                    self.performSegue(withIdentifier: "hubSegue", sender: self)
                })
                
            })
            
        }
    }
    //End of Twitter button setup
    
    @IBAction func loginOnClick(_ sender: Any) {
        guard let inputEmail = emailTextField.text else { return }
        guard let inputPassword = passwordTextField.text else { return }
        
        if isValidEmail(inputEmail: inputEmail) && isValidPassword(inputPassword: inputPassword) {
            segueTo()
        }
        
    }
    //TODO: need a unique email validator
    func isValidEmail(inputEmail: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: inputEmail)
    }
    
    func isValidPassword(inputPassword :String) -> Bool {
        return inputPassword.characters.count > 6
    }
    
    func segueFromOAuth(data: String) {
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "hubSegue" {
            let controller = segue.destination as! HubViewController
            controller.uid = uid
        }
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
