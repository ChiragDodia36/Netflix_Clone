//
//  AuthView.swift
//  Netflix
//
//  Created by Chirag Dodia on 9/2/25.
//

import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authService: LocalAuthService
    @EnvironmentObject var profileService: ProfileService
    @State private var isLoginMode = true
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isAuthenticating = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color.red.opacity(0.3),
                    Color.black
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Logo and header
                VStack(spacing: 20) {
                    // Cinemora Logo
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.red, Color.red.opacity(0.8)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 40, height: 40)
                            
                            HStack(spacing: 2) {
                                Rectangle()
                                    .fill(Color.white)
                                    .frame(width: 3, height: 12)
                                Rectangle()
                                    .fill(Color.white)
                                    .frame(width: 3, height: 12)
                                Rectangle()
                                    .fill(Color.white)
                                    .frame(width: 3, height: 12)
                            }
                        }
                        
                        Text("Cinemora")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 60)
                    
                    Text(isLoginMode ? "Welcome Back" : "Join Cinemora")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Auth form
                VStack(spacing: 24) {
                    // Name fields (signup only)
                    if !isLoginMode {
                        VStack(spacing: 16) {
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("First Name")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    
                                    TextField("Enter first name", text: $firstName)
                                        .textFieldStyle(CustomTextFieldStyle())
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Last Name")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    
                                    TextField("Enter last name", text: $lastName)
                                        .textFieldStyle(CustomTextFieldStyle())
                                }
                            }
                        }
                    }
                    
                    // Email field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        TextField("Enter your email", text: $email)
                            .textFieldStyle(CustomTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    
                    // Password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        SecureField("Enter your password", text: $password)
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                    
                    // Confirm password (signup only)
                    if !isLoginMode {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                            
                            SecureField("Confirm your password", text: $confirmPassword)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                    }
                    
                    // Auth button
                    Button(action: handleAuth) {
                        HStack {
                            if isAuthenticating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)
                            } else {
                                if isLoginMode {
                                    Text("Sign In")
                                } else {
                                    Text("Create Account")
                                }
                            }
                        }
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.red, Color.red.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: Color.red.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(isButtonDisabled || isAuthenticating)
                    .opacity((isButtonDisabled || isAuthenticating) ? 0.6 : 1.0)
                    
                    // Toggle auth mode
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isLoginMode.toggle()
                            clearForm()
                        }
                    }) {
                        HStack {
                            Text(isLoginMode ? "Don't have an account?" : "Already have an account?")
                                .foregroundColor(.white.opacity(0.7))
                            Text(isLoginMode ? "Sign Up" : "Sign In")
                                .foregroundColor(.red)
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Footer
                VStack(spacing: 16) {
                    Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    Text("© 2024 Cinemora. All rights reserved.")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.bottom, 40)
            }
        }
        .alert("Authentication Error", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .alert("Error", isPresented: .constant(authService.errorMessage != nil)) {
            Button("OK") { 
                authService.errorMessage = nil
            }
        } message: {
            Text(authService.errorMessage ?? "An unknown error occurred")
        }
    }
    
    private var isButtonDisabled: Bool {
        if isLoginMode {
            return email.isEmpty || password.isEmpty
        } else {
            return email.isEmpty || password.isEmpty || confirmPassword.isEmpty
        }
    }
    
    private func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        firstName = ""
        lastName = ""
    }
    
    private func handleAuth() {
        // Basic validation
        if !isValidEmail(email) {
            alertMessage = "Please enter a valid email address"
            showAlert = true
            return
        }
        
        if password.count < 6 {
            alertMessage = "Password must be at least 6 characters long"
            showAlert = true
            return
        }
        
        if !isLoginMode && password != confirmPassword {
            alertMessage = "Passwords do not match"
            showAlert = true
            return
        }
        
        isAuthenticating = true
        
        // Perform authentication
        let result: Result<LocalUser, AuthError>
        
        if isLoginMode {
            result = authService.signIn(email: email, password: password)
        } else {
            result = authService.signUp(
                email: email,
                password: password,
                firstName: firstName.isEmpty ? nil : firstName,
                lastName: lastName.isEmpty ? nil : lastName
            )
        }
        
        switch result {
        case .success:
            // Authentication successful - reset profile service for the new session
            profileService.resetForNewUser()
            print("Authentication successful")
        case .failure(let error):
            alertMessage = error.localizedDescription
            showAlert = true
        }
        
        isAuthenticating = false
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .foregroundColor(.white)
            .font(.system(size: 16))
    }
}

#Preview {
    AuthView()
}
