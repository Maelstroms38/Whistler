//
//  RecordVoiceViewController.swift
//  Whistler
//
//  Created by Michael Stromer on 5/3/16.
//  Copyright © 2016 Michael Stromer. All rights reserved.
//

import UIKit
import AVFoundation

class RecordVoiceViewController: UIViewController, AVAudioRecorderDelegate {

    var stackView: UIStackView!
    var recordButton: UIButton!
    
    var recordingSession: AVAudioSession!
    var voiceRecorder: AVAudioRecorder!
    
    var playButton: UIButton!
    var voicePlayer: AVAudioPlayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Record Voice"
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Record", style: .Plain, target: nil, action: nil)
        
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] (allowed: Bool) -> Void in
                dispatch_async(dispatch_get_main_queue()) {
                    if allowed {
                        self.loadRecordingUI()
                    } else {
                        self.loadFailUI()
                    }
                }
            }
        } catch {
            self.loadFailUI()
        }
    }
    
    func loadRecordingUI() {
        recordButton = UIButton()
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        recordButton.setTitle("Tap to Record", forState: .Normal)
        recordButton.titleLabel?.font = UIFont.preferredFontForTextStyle(UIFontTextStyleTitle1)
        recordButton.addTarget(self, action: #selector(RecordVoiceViewController.recordTapped), forControlEvents: .TouchUpInside)
        stackView.addArrangedSubview(recordButton)
        
        playButton = UIButton()
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.setTitle("Tap to Play", forState: .Normal)
        playButton.hidden = true
        playButton.alpha = 0
        playButton.titleLabel?.font = UIFont.preferredFontForTextStyle(UIFontTextStyleTitle1)
        playButton.addTarget(self, action: #selector(RecordVoiceViewController.playTapped), forControlEvents: .TouchUpInside)
        stackView.addArrangedSubview(playButton)
    }
    
    func loadFailUI() {
        let failLabel = UILabel()
        failLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        failLabel.text = "Recording failed: please ensure the app has access to your microphone."
        failLabel.numberOfLines = 0
        
        stackView.addArrangedSubview(failLabel)
    }
    func recordTapped() {
        if voiceRecorder == nil {
            startRecording()
            if !playButton.hidden {
                UIView.animateWithDuration(0.35) { [unowned self] in
                    self.playButton.hidden = true
                    self.playButton.alpha = 0
                }
            }
        } else {
            finishRecording(success: true)
        }
    }
    class func getDocumentsDirectory() -> NSString {
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true) as [String]
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    class func getWhistleURL() -> NSURL {
        let audioFilename = getDocumentsDirectory().stringByAppendingPathComponent("whistle.m4a")
        let audioURL = NSURL(fileURLWithPath: audioFilename)
        
        return audioURL
    }
    func startRecording() {
        // 1
        view.backgroundColor = UIColor(red: 0.6, green: 0, blue: 0, alpha: 1)
        
        // 2
        recordButton.setTitle("Tap to Stop", forState: .Normal)
        
        // 3
        let audioURL = RecordVoiceViewController.getWhistleURL()
        print(audioURL.absoluteString)
        
        // 4
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000.0,
            AVNumberOfChannelsKey: 1 as NSNumber,
            AVEncoderAudioQualityKey: AVAudioQuality.High.rawValue
        ]
        
        do {
            // 5
            voiceRecorder = try AVAudioRecorder(URL: audioURL, settings: settings)
            voiceRecorder.delegate = self
            voiceRecorder.record()
        } catch {
            finishRecording(success: false)
        }
    }
    func finishRecording(success success: Bool) {
        view.backgroundColor = UIColor(red: 0, green: 0.6, blue: 0, alpha: 1)
        
        voiceRecorder.stop()
        voiceRecorder = nil
        
        if success {
            recordButton.setTitle("Tap to Re-record", forState: .Normal)
            if playButton.hidden {
                UIView.animateWithDuration(0.35) { [unowned self] in
                    self.playButton.hidden = false
                    self.playButton.alpha = 1
                }
            }
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Next", style: .Plain, target: self, action: #selector(RecordVoiceViewController.nextTapped))
        } else {
            recordButton.setTitle("Tap to Record", forState: .Normal)
            
            let ac = UIAlertController(title: "Record failed", message: "There was a problem recording your whistle; please try again.", preferredStyle: .Alert)
            ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            presentViewController(ac, animated: true, completion: nil)
        }
    }
    func nextTapped() {
        let vc = SelectGenreViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func loadView() {
        super.loadView()
        
        view.backgroundColor = UIColor.grayColor()
        
        stackView = UIStackView()
        stackView.spacing = 30
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = UIStackViewDistribution.FillEqually
        stackView.alignment = UIStackViewAlignment.Center
        stackView.axis = .Vertical
        view.addSubview(stackView)
        
        //VFL Visual Formatting Language
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[stackView]|", options: NSLayoutFormatOptions.AlignAllCenterX, metrics: nil, views: ["stackView": stackView]))
        view.addConstraint(NSLayoutConstraint(item: stackView, attribute: .CenterY, relatedBy: .Equal, toItem: view, attribute: .CenterY, multiplier: 1, constant:0))
    }
    func playTapped() {
        let audioURL = RecordVoiceViewController.getWhistleURL()
        
        do {
            voicePlayer = try AVAudioPlayer(contentsOfURL: audioURL)
            voicePlayer.play()
        } catch {
            let ac = UIAlertController(title: "Playback failed", message: "There was a problem playing your whistle; please try re-recording.", preferredStyle: .Alert)
            ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            presentViewController(ac, animated: true, completion: nil)
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
