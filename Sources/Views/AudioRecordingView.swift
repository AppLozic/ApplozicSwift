//
//  AudioRecordingView.swift
//  Applozic
//
//  Created by Shivam Pokhriyal on 17/08/18.
//

import Foundation

import AVFoundation

public protocol ALKAudioRecorderViewProtocol: AnyObject {
    func cancelAudioRecording()
}

open class ALKAudioRecorderView: UIView, Localizable {
    var configuration: ALKConfiguration!

    private var isTimerStart: Bool = false
    private var timer = Timer()
    private var counter = 0
    private var previousGestureLocation: CGFloat = 0.0
    private var slideToCancelStartLocation: CGFloat = 0.0
    private var recordingViewStartLocation: CGFloat = 0.0
    private var redDotStartLocation: CGFloat = 0.0

    weak var delegate: ALKAudioRecorderViewProtocol?

    lazy var slideToCancel: UILabel = {
        let label = self.commonLabel()
        label.font = UIFont(name: "HelveticaNeue", size: 15)
        label.textColor = UIColor(red: 140, green: 137, blue: 137)
        return label
    }()

    let leftArrow: UIImageView = {
        var image = UIImage(named: "leftArrow", in: Bundle.applozic, compatibleWith: nil)
        image = image?.imageFlippedForRightToLeftLayoutDirection()
        let imageView = UIImageView(image: image)
        imageView.heightAnchor.constraint(equalToConstant: 11).isActive = true
        return imageView
    }()

    lazy var slideView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [self.leftArrow, self.slideToCancel])
        stackView.alignment = .fill
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.spacing = 10.0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    let redDot: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 4
        view.clipsToBounds = true
        view.backgroundColor = UIColor(red: 255, green: 14, blue: 0)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    lazy var recordingLabel: UILabel = {
        let label = self.commonLabel()
        label.font = UIFont(name: "HelveticaNeue", size: 13)
        label.textColor = UIColor(red: 255, green: 14, blue: 0)
        label.text = "RecordingMessage"
        return label
    }()

    lazy var recordingValue: UILabel = {
        let label = self.commonLabel()
        label.font = UIFont(name: "HelveticaNeue-Thin", size: 13)
        label.textColor = UIColor(red: 0, green: 0, blue: 0)
        label.text = "00:00"
        return label
    }()

    lazy var recordingView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [self.recordingLabel, self.recordingValue])
        stackView.alignment = .leading
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.spacing = 2.0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private func commonLabel() -> UILabel {
        let label = UILabel(frame: CGRect.zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = UIColor.clear
        label.alpha = 0.0
        label.textAlignment = .center
        label.textColor = UIColor.black
        return label
    }

    func setAudioRecViewDelegate(recorderDelegate: ALKAudioRecorderViewProtocol?) {
        delegate = recorderDelegate
    }

    func animateView() {
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            self.slideToCancel.alpha = 1.0
            self.recordingLabel.alpha = 1.0
            self.recordingValue.alpha = 1.0
            self.invalidateIntrinsicContentSize()
            self.setNeedsLayout()
            self.layoutIfNeeded()
        })
    }

    public init(frame: CGRect, configuration: ALKConfiguration) {
        super.init(frame: frame)
        self.configuration = configuration
        translatesAutoresizingMaskIntoConstraints = false
        setupUI()
        layer.cornerRadius = 12
        animateView()
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(redDot)
        addSubview(slideView)
        addSubview(recordingView)

        redDot.widthAnchor.constraint(equalToConstant: 8).isActive = true
        redDot.heightAnchor.constraint(equalToConstant: 8).isActive = true
        redDot.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20).isActive = true
        redDot.bottomAnchor.constraint(equalTo: centerYAnchor, constant: -5).isActive = true

        recordingView.leadingAnchor.constraint(equalTo: redDot.leadingAnchor, constant: 20).isActive = true
        recordingView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        recordingView.widthAnchor.constraint(equalToConstant: 60).isActive = true

        slideView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20).isActive = true
        slideView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        slideView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor).isActive = true
    }

    private func stopTimer() {
        if isTimerStart == true {
            isTimerStart = false
            timer.invalidate()
        }
    }

    private func initializeParameters() {
        backgroundColor = UIColor.color(.none)
        slideToCancel.text = localizedString(forKey: "SlideToCancelMessage", withDefaultValue: SystemMessage.Microphone.SlideToCancel, fileName: configuration.localizedStringFileName)
        recordingLabel.text = localizedString(forKey: "RecordingMessage", withDefaultValue: SystemMessage.Microphone.Recording, fileName: configuration.localizedStringFileName)
        redDot.backgroundColor = UIColor(red: 255, green: 14, blue: 0)
        recordingValue.text = "00:00"

        previousGestureLocation = 0.0

        if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
            slideToCancelStartLocation = slideView.frame.origin.x
            recordingViewStartLocation = recordingView.frame.origin.x - 10.0
            redDotStartLocation = redDot.frame.origin.x - 5.0
        } else {
            slideToCancelStartLocation = slideView.frame.origin.x - slideToCancel.intrinsicContentSize.width
            recordingViewStartLocation = recordingView.frame.origin.x + recordingLabel.intrinsicContentSize.width + 10.0
            redDotStartLocation = redDot.frame.origin.x + 5.0
        }
    }

    @objc private func updateCounter() {
        counter += 1

        // min
        let min = (counter / 60) % 60
        let sec = (counter % 60)
        var minStr = String(min)
        var secStr = String(sec)
        if sec < 10 { secStr = "0\(secStr)" }
        if min < 10 { minStr = "0\(minStr)" }
        recordingValue.text = "\(minStr):\(secStr)"
    }

    @objc public func userDidStartRecording() {
        isTimerStart = true
        counter = 0

        initializeParameters()
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateCounter), userInfo: nil, repeats: true)
    }

    @objc public func userDidStopRecording() {
        slideToCancel.text = nil
        recordingLabel.text = nil
        recordingValue.text = nil
        redDot.backgroundColor = UIColor.clear
        stopTimer()
    }

    @objc public func isRecordingTimeSufficient() -> Bool {
        if counter < 1 {
            return false
        } else {
            return true
        }
    }

    @objc public func moveView(location: CGPoint) {
        if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
            moveViewRTL(location: location)
            return
        }
        let newPos = slideView.frame.origin.x + (location.x - previousGestureLocation)
        if newPos > slideToCancelStartLocation {
            return
        }
        if slideView.frame.origin.x <= recordingViewStartLocation,
           redDot.frame.origin.x + (location.x - previousGestureLocation) <= redDotStartLocation
        {
            recordingView.frame.origin.x += (location.x - previousGestureLocation)
            redDot.frame.origin.x += (location.x - previousGestureLocation)
            if recordingView.frame.origin.x <= 0.0 {
                delegate?.cancelAudioRecording()
            }
        }
        slideView.frame.origin.x = newPos
        previousGestureLocation = location.x
    }

    private func moveViewRTL(location: CGPoint) {
        let newPos = slideView.frame.origin.x + (location.x - previousGestureLocation)

        if newPos < slideToCancelStartLocation {
            return
        }
        let slideViewEnd = slideView.frame.origin.x + slideView.frame.size.width
        if slideViewEnd >= recordingViewStartLocation,
           redDot.frame.origin.x + (location.x - previousGestureLocation) >= redDotStartLocation
        {
            recordingView.frame.origin.x += (location.x - previousGestureLocation)
            redDot.frame.origin.x += (location.x - previousGestureLocation)
            if recordingView.frame.origin.x + recordingView.frame.size.width >= redDotStartLocation + 30 {
                delegate?.cancelAudioRecording()
            }
        }
        slideView.frame.origin.x = newPos
        previousGestureLocation = location.x
    }
}
