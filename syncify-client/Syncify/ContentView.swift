//
//  ContentView.swift
//  Syncify
//
//  Created by Rishi Roy on 11/23/23.
//

import SwiftUI
import Foundation
import UserNotifications

struct ContentView: View {
    @State private var sessionToken: String = ""
    @State private var serverUrl: String = Config.SERVER_URL
    @State private var clientId: Int = -1
    @State private var controller: String = "none"
    @State private var takeControlNow: Bool = false
    
    @State private var connectLoading = false
    @State private var controlLoading = false
    @State private var statusMessage: String = "Disconnected"

    @State private var lastServerUrl: String = "last"
    @State private var lastSessionToken: String = "last"
    @State private var lastTimestamp: Double = 0.0

    var body: some View {
        VStack {
            Text("Syncify")
                .font(
                    .custom("Avenir", fixedSize: 60)
                    .weight(.bold))
                .foregroundColor(Color(red: 0.72, green: 0.58, blue: 0.36, opacity: 1.0))
                .padding(.bottom, 40)
            Image("logo")
                .resizable()
                .frame(width: 180.0, height: 180.0)
            Text("Start a new session or connect to an existing one")
                .multilineTextAlignment(.center)
                .frame(width: 220)
                .padding(.top, 20)
                .padding(.bottom, 10)

            TextField("session name",
                      text: $sessionToken)
                .frame(width: 180)
                .padding(.bottom, 5)
            
            if Config.SERVER_URL == "" {
                TextField("server url",
                          text: $serverUrl)
                    .frame(width: 180)
                    .disableAutocorrection(true)
                    .padding(.bottom, 5)
            }
            
            Text(statusMessage)
                .frame(width: 300)
                .padding(5)
                .padding(.top, 20)
                .font(.title2)
            
            Button(action: {
                Task {
                    controlLoading = true
                    takeControl()
                    controlLoading = false
                }
            }, label: {
                Text("Take Control")
            })
            .disabled(controlLoading)
        }
        .frame(width: 428, height: 610)
        .onAppear {
            serverUrl = Config.SERVER_URL
            self.startUpdateLoop()
            
//            request notifcation permission
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
                if granted {
                    print("Notification authorization granted")
                } else if let error = error {
                    print("Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    
    func startUpdateLoop() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            Task {
                do {
                    try await updateLoop()
                } catch {
                    print("Error: \(error)")
                }
            }
        }
    }
    func updateLoop() async throws {
        print("syncing...")
        print("server url: " + serverUrl)
        
        if sessionToken == "" || serverUrl == "" {
            return
        }
        
        if serverUrl != lastServerUrl || sessionToken != lastSessionToken {
            print("reconnecting...")
            try await serverConnect()
            lastServerUrl = serverUrl
            lastSessionToken = sessionToken
        }
        
        controller = try await getController()
        let trackTS: Double = Double(runApplescript(script: "tell application \"Spotify\" to return player position") ?? "") ?? 0
        let trackId: String = runApplescript(script: "tell application \"Spotify\" to return id of current track") ?? ""
        let playerState: String = runApplescript(script: "tell application \"Spotify\" to return player state") ?? ""
        print("track loc   :" + String(trackTS))
        print("track id    :" + trackId)
        print("player state:" + playerState)
        print("server url  :" + serverUrl)
        
        var dataS: [String: Any] = [
            "session_token": sessionToken,
            "timestamp": String(trackTS),
            "id": String(trackId),
            "player-state": String(playerState)
        ]
        print(dataS)
        
//        this client is the controller
        if controller == String(clientId) {
            print("this is the controller")
            try await sendTimestamp(dataS: dataS)
            statusMessage = "Following along to you"
        } else if takeControlNow {
//            make this client the controller
            print("making this client the controller")
            takeControlNow = false
            try await setController()
            statusMessage = "Following along to you"
        } else {
//            this client is not the controller
            print("this is NOT the controller")
            let serverUpdate = try await getTimestamp()
            print("diff: " + String(abs((Double(serverUpdate.timestamp) ?? 0) - lastTimestamp)))
            if abs((Double(serverUpdate.timestamp) ?? 0) - lastTimestamp) == 0 {
                statusMessage = "Others are not broadcasting"
                return;
            }
            lastTimestamp = Double(serverUpdate.timestamp) ?? 0
            if serverUpdate != nil && String(trackTS) != "missing value" {
                if trackId != serverUpdate.id {
                    print("changing this player track...")
                    print(serverUpdate.id)
                    runApplescript(script: "tell application \"Spotify\" to play track \"" + serverUpdate.id + "\"")
                    dataS["id"] = serverUpdate.id
                    print("changing this player timestamp...")
                    runApplescript(script: "tell application \"Spotify\" to set player position to " + serverUpdate.timestamp)
                    dataS["timestamp"] = serverUpdate.timestamp
                }
                if abs(trackTS - (Double(serverUpdate.timestamp) ?? 0)) >= 4 {
                    print("changing this player timestamp...")
                    runApplescript(script: "tell application \"Spotify\" to set player position to " + serverUpdate.timestamp)
                    dataS["timestamp"] = serverUpdate.timestamp
                }
                if playerState != serverUpdate.playerState {
                    runApplescript(script: "tell application \"Spotify\" to playpause")
                }
                statusMessage = "Following along with others"
            }
        }
        print("")
    }


    enum FetcherError: Error {
        case invalidURL
        case missingData
        case invalidResponse
    }
    
    struct ConnectReq: Codable {
        let clientId: Int
    }
    func serverConnect() async throws -> Int {

        guard let url = URL(string: serverUrl + "/connect") else {
            throw FetcherError.invalidURL
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let res = try JSONDecoder().decode(ConnectReq.self, from: data)
            print("client id: " + String(res.clientId))
            clientId = res.clientId
            return res.clientId
        } catch {
            throw FetcherError.invalidURL
        }
    }
    
    struct controllerReq: Codable {
        let clientId: String
    }
    func getController() async throws -> String {
        
        guard let url = URL(string: serverUrl + "/get-controller") else {
            throw FetcherError.invalidURL
        }
        
        let requestData = try JSONSerialization.data(withJSONObject: ["session_token": sessionToken, "client_id": clientId])
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        request.httpBody = requestData
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let responseString = String(data: data, encoding: .utf8) {
                print("controller: " + responseString)
                return responseString
            } else {
                throw FetcherError.invalidResponse
            }
        } catch {
            throw FetcherError.invalidResponse
        }
    }
    
    func sendTimestamp(dataS: [String: Any]) async throws {
        guard let url = URL(string: serverUrl + "/send-timestamp") else {
            throw FetcherError.invalidURL
        }
        
        let requestData = try JSONSerialization.data(withJSONObject: dataS)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        request.httpBody = requestData
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let responseString = String(data: data, encoding: .utf8) {
                return
            } else {
                throw FetcherError.invalidResponse
            }
        } catch {
            throw FetcherError.invalidResponse
        }
    }
    
    func takeControl() {
        takeControlNow = true
        print("will take control")
    }
    
    func setController() async throws {
        guard let url = URL(string: serverUrl + "/set-controller") else {
            throw FetcherError.invalidURL
        }
        
        let requestData = try JSONSerialization.data(withJSONObject: ["session_token": sessionToken, "client_id": clientId])
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        request.httpBody = requestData
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let responseString = String(data: data, encoding: .utf8) {
                return
            } else {
                throw FetcherError.invalidResponse
            }
        } catch {
            throw FetcherError.invalidResponse
        }
    }
    
    struct timestampReq: Codable {
        let session_token: String
        let timestamp: String
        let id: String
        let playerState: String

        enum CodingKeys: String, CodingKey {
            case session_token
            case timestamp
            case id
            case playerState = "player-state"
        }
    }
    func getTimestamp() async throws -> timestampReq {
        guard let url = URL(string: serverUrl + "/get-timestamp") else {
            throw FetcherError.invalidURL
        }
        
        let requestData = try JSONSerialization.data(withJSONObject: ["session_token": sessionToken])
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        request.httpBody = requestData
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let jsonString = String(data: data, encoding: .utf8)
            print("Response:", jsonString ?? "Empty response")

            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]

            let decoder = JSONDecoder()
            let res = try decoder.decode(timestampReq.self, from: data)
            return res
        } catch {
            throw FetcherError.invalidResponse
        }
    }

    func runApplescript(script: String) -> String? {

        let process = Process()
        process.launchPath = "/usr/bin/osascript"
        process.arguments = ["-e", script]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
            return output
        }
        return "failure to run applescript"
    }
    
    func sendNotification(subtitle: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = "Syncify"
        content.subtitle = subtitle
        content.body = body
        content.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
            
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    ContentView()
}

