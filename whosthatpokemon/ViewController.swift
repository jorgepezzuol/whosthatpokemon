//
//  ViewController.swift
//  whosthatpokemon
//
//  Created by Generous on 25/03/2020.
//  Copyright © 2020 Pezzuol. All rights reserved.
//

import UIKit
import Speech
import AVFoundation

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension UIImageView {
  func setImageColor(color: UIColor) {
    let templateImage = self.image?.withRenderingMode(.alwaysTemplate)
    self.image = templateImage
    self.tintColor = color
  }
}

class ViewController: UIViewController, SFSpeechRecognizerDelegate {

    @IBOutlet weak var tfPokemonName: UITextField!
    @IBOutlet weak var btnMic: UIButton!
    @IBOutlet weak var imgPokemon: UIImageView!
    @IBOutlet weak var lblPokemonName: UILabel!
    
    var urlImgPokemon: String?
    var player: AVAudioPlayer?
    
    /* speech stuff */
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    /* end speech stuff */
    
    @IBAction func pokemonNameTyped(_ sender: Any) {
        
        self.checkName()

    }
    
    @IBAction func dontKnow(_ sender: UIButton) {
        
        guard let name = self.lblPokemonName.text?.lowercased() else { return }
        
        self.lblPokemonName.text = "it's \(name)!"
        self.lblPokemonName.isHidden = false
        
        let url = URL(string: self.urlImgPokemon!)
        let data = try? Data(contentsOf: url!)
        self.imgPokemon.image = UIImage(data: data!)
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            
            self.lblPokemonName.isHidden = true
            
            self.fetchAPI(pokemon: Int.random(in: 0 ... 150))
        }
        
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.hideKeyboardWhenTappedAround()
        self.enableSpeech()
        
        self.lblPokemonName.isHidden = true
        
        fetchAPI(pokemon: Int.random(in: 0 ... 150))
                
    }
    
    func playSound(soundName: String) {
        let url = Bundle.main.url(forResource: soundName, withExtension: "mp3")
        player = try! AVAudioPlayer(contentsOf: url!)
        player!.play()
        
    }
    
    func checkName() {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        
            guard let name = self.tfPokemonName.text?.lowercased() else { return }

            if name.count >= 3 {
                
                if name == self.lblPokemonName.text {
                    
                    self.lblPokemonName.text = "it's \(name)!"
                    self.lblPokemonName.isHidden = false
                    
                    let url = URL(string: self.urlImgPokemon!)
                    let data = try? Data(contentsOf: url!)
                    self.imgPokemon.image = UIImage(data: data!)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        
                        self.lblPokemonName.isHidden = true
                        
                        self.fetchAPI(pokemon: Int.random(in: 0 ... 150))
                    }
                    
                }
            }
            
        }
    }
    
    func fetchAPI(pokemon: Int) {
        
        self.playSound(soundName: "whosthatpokemon")
        
        guard let url = URL(string: "https://pokeapi.co/api/v2/pokemon/\(pokemon)/") else { return }
        URLSession.shared.dataTask(with: url) { (data, resp, err) in
            // make sure to check error / resp
            
            DispatchQueue.main.async {
                do {
                    guard let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: AnyObject] else { return }
                                        
                    self.lblPokemonName.text = (json["name"] as! String)
                                    
                    let url = URL(string: json["sprites"]!["front_default"] as! String)
                    let data = try? Data(contentsOf: url!)
                    self.imgPokemon.image = UIImage(data: data!)
                    self.urlImgPokemon = (json["sprites"]!["front_default"] as! String)
                    
                    self.imgPokemon.setImageColor(color: UIColor.black)
                    
                } catch {
                    print("Failed to decode JSON:", error)
                }
            }
            
        }.resume()
    }
       

    func enableSpeech() {
        
        btnMic.isEnabled = false

        speechRecognizer.delegate = self

        SFSpeechRecognizer.requestAuthorization { (authStatus) in

            var isButtonEnabled = false

            switch authStatus {
            case .authorized:
                isButtonEnabled = true

            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")

            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restricted on this device")

            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            @unknown default:
                fatalError()
            }

            OperationQueue.main.addOperation() {
                self.btnMic.isEnabled = isButtonEnabled
            }
        }
        
    }
    
    @IBAction func microphoneTapped(_ sender: AnyObject) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            btnMic.isEnabled = false
            btnMic.setImage(UIImage(named: "microphone"), for: UIControl.State.normal)
        } else {
            startRecording()
            btnMic.setImage(UIImage(named: "mic-recording"), for: UIControl.State.normal)

        }
    }
    
    func startRecording() {

        if recognitionTask != nil {  //1
            recognitionTask?.cancel()
            recognitionTask = nil
        }

        let audioSession = AVAudioSession.sharedInstance()  //2
        do {
            try audioSession.setCategory(AVAudioSession.Category.record)
            try audioSession.setMode(AVAudioSession.Mode.measurement)
            try audioSession.setActive(true)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()  //3

        let inputNode = audioEngine.inputNode
                
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        } //5

        recognitionRequest.shouldReportPartialResults = true  //6

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in  //7

            var isFinal = false  //8

            if result != nil {

                self.tfPokemonName.text = result?.bestTranscription.formattedString  //9
                isFinal = (result?.isFinal)!
                
                self.checkName()
            }

            if error != nil || isFinal {  //10
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)

                self.recognitionRequest = nil
                self.recognitionTask = nil

                self.btnMic.isEnabled = true
            }
        })

        let recordingFormat = inputNode.outputFormat(forBus: 0)  //11
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()  //12

        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }

    }

    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            btnMic.isEnabled = true
        } else {
            btnMic.isEnabled = false
        }
    }
}

