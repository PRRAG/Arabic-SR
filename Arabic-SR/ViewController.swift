//
//  ViewController.swift
//  Arabic-SR
//
//  Created by Pavly Remon on 5/10/19.
//  Copyright © 2019 Pavly Remon. All rights reserved.
//

import UIKit
import TLSphinx
import AVFoundation
class ViewController: UIViewController ,AVAudioPlayerDelegate,AVAudioRecorderDelegate{
    
    @IBOutlet weak var record_bn: UIButton!
    @IBOutlet weak var RecordOut: UILabel!
    var soundrecorder : AVAudioRecorder!
    var soundplayer : AVAudioPlayer!
    var recordFileName : URL!
    var recordWavFile : URL!
    var wavAudioFile : String = "wavAudioFile.wav"
    var en_ar :[Character: String] =
        [ "A":"ء","B":"آ","C":"أ","D":"ؤ","E":"إ","F":"ئ","G":"ا",
          "H":"ب","I":"ة","J":"ت","K":"ث","L":"ج","M":"ح","N":"خ","O":"د",
          "P":"ذ","Q":"ر","R":"ز","S":"س","T":"ش","U":"ص","V":"ض","W":"ط","X":"ظ",
          "Y":"ع","Z":"غ","a":"ف","b":"ق","c":"ك","d":"ل","e":"م","f":"ن","g":"ه",
          "h":"و","i":"ى","j":"ي","k":"","l":"","m":"","n":"","o":"","p":"","q":"",
          "r":"","s":""," ":" "]
    override func viewDidLoad() {
        super.viewDidLoad()
        recordWavFile = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(wavAudioFile)
        setupRecorder()
    }
    @IBAction func Record_Act(_ sender: Any) {
        if record_bn.titleLabel?.text == "Record" {
            soundrecorder.record()
            record_bn.setTitle("Stop", for: .normal)
        }else{
            soundrecorder.stop()
            record_bn.setTitle("Record", for: .normal)
        }
    }
    func setupRecorder(){
        
        print(recordFileName as Any)
        do{
            try FileManager.default.removeItem(at: recordWavFile)
        }catch{
            print("No previous files")
        }
        let recordSetting = [AVFormatIDKey : kAudioFormatLinearPCM,
                             AVSampleRateKey:16000,
                             AVLinearPCMBitDepthKey:32,
                             AVNumberOfChannelsKey:1,
                             AVLinearPCMIsBigEndianKey : "false",
                             AVLinearPCMIsFloatKey :"true"] as [String : Any]
        do{
            // let recordedFileName = getDocumentDirector().appendingPathComponent(audioFile)
            soundrecorder = try AVAudioRecorder(url: recordWavFile, settings: recordSetting)
            soundrecorder.delegate=self
            soundrecorder.prepareToRecord()
        }catch{
            print(error)
        }
    }
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        
        print(recordWavFile!)
        speech_to_text()
    }
    func getModelPath() -> NSString? {
        return Bundle(for: ViewController.self).path(forResource: "MP", ofType: nil) as NSString?
    }
    func speech_to_text (){
        guard let modelPath = getModelPath() else {
            print("Can't access pocketsphinx model. Bundle root: \(Bundle.main)")
            return
        }
        
        let hmm = modelPath.appendingPathComponent("asr_ar.ci_cont-512-60-22-4")
        let lm = modelPath.appendingPathComponent("asr_ar.lm")
        let dict = modelPath.appendingPathComponent("asr_ar.dic")
        //let testwav = modelPath.appendingPathComponent("t_2.wav")
        guard let config = Config(args: ("-hmm", hmm), ("-lm", lm), ("-dict", dict)) else {
            print("Can't run test without a valid config")
            return
        }
        
        config.showDebugInfo = false
        
        guard let decoders = Decoder(config:config) else {
            print("Can't run test without a decoder")
            return
        }
        let audiofile = recordWavFile
        
        let index = audiofile!.absoluteString.index(audiofile!.absoluteString.startIndex, offsetBy: 7)
        //let decodeFileName = audiofile!.absoluteString.substring(from: index)
        let decodeFileName = String((audiofile!.absoluteString)[index...])
        print("\(decodeFileName)")
        do{
            try decoders.decodeSpeech(atPath:  decodeFileName /*testwav*/  ){
                
                if let hyp: Hypothesis = $0 {
                    // Print the decoder text and score
                    print("Text: \(self.conv_to_arab(output: hyp.text)) - Score: \(hyp.score)")
                    self.RecordOut.text = ("\(self.conv_to_arab(output: hyp.text))")
                } else {
                    // Can't decode any speech because of an error
                    print("No")
                }
            }
        }catch{
            print(error)
        }
        
        
    }
    func conv_to_arab(output : String)-> String{
        var outStr:String = ""
        
        
        for i in output{
            outStr.append(en_ar[i]!)
        }
        return outStr
    }
}

