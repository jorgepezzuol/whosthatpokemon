//
//  ViewController.swift
//  whosthatpokemon
//
//  Created by Generous on 25/03/2020.
//  Copyright © 2020 Pezzuol. All rights reserved.
//

import UIKit
import Speech

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

class ViewController: UIViewController, SFSpeechRecognizerDelegate {

    @IBOutlet weak var tfPokemonName: UITextField!
    @IBOutlet weak var btnMic: UIButton!
    
    /* speech stuff */
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    /* end speech stuff */
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        
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

