//
//  ViewController.swift
//  jellapiCodes
//
//  Created by Jellapi on 2/21/24.
//

import UIKit
import AVFoundation
import NDI
import VideoToolbox

class ViewController: UIViewController {
  
  @IBOutlet weak var videoImageView: UIImageView!
  private var ndi: NDI?
  private var captureSession = AVCaptureSession()
  private var captureDeviceInput: AVCaptureDeviceInput!
  private var captureDeviceAudioInput: AVCaptureDeviceInput!
  private var videoDataOutput: AVCaptureVideoDataOutput!
  private var videoDataOutput2: AVCaptureVideoDataOutput!
  private var audioDataOutput: AVCaptureAudioDataOutput!
  private var device: AVCaptureDevice!
  private var isSending: Bool = false
  private var currentOrientation: AVCaptureVideoOrientation = .portrait
  
  private var previewLayer: AVCaptureVideoPreviewLayer!
  var sessionAtSourceTime: CMTime? = nil
  var isRecording = false
  var testCount = 0
  
  @IBAction func cameraSideChange(_ sender: Any) {
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    device = AVCaptureDevice.default(.builtInTelephotoCamera, for: .video, position: .back)
    do {
      try device?.lockForConfiguration()
      
      let zoomFactor:CGFloat = 1.2//device?.activeFormat.videoMaxZoomFactor ?? 1
      print(device?.activeFormat.videoMaxZoomFactor ?? 1)
      device?.videoZoomFactor = zoomFactor
      device?.unlockForConfiguration()
    } catch {
      //Catch error from lockForConfiguration
    }
    
    self.captureSession.sessionPreset = getSupportPreset(device, wantPreset: .vga640x480)
    
    ndi = NDI()
    ndi?.setWatermarkImage(UIImage(named: "WaterMark"), withPosition: CGPoint(x: 0.5, y:0.6))
    
    captureDeviceInput = try! AVCaptureDeviceInput(device: device)
    if captureSession.canAddInput(captureDeviceInput) {
      captureSession.addInput(captureDeviceInput)
    } else {
    }
    
    let mic = AVCaptureDevice.default(for: AVMediaType.audio)
    captureDeviceAudioInput = try! AVCaptureDeviceInput(device: mic!)
    if captureSession.canAddInput(captureDeviceAudioInput) {
      captureSession.addInput(captureDeviceAudioInput)
    }
    
    
    videoDataOutput = AVCaptureVideoDataOutput()
    //        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey : kCVPixelFormatType_32BGRA] as [String : Any]
    //        videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as String) : NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)]
    videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as String) : NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
    
    videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
    videoDataOutput.alwaysDiscardsLateVideoFrames = true
    
    if captureSession.canAddOutput(videoDataOutput) {
      captureSession.addOutput(videoDataOutput)
    }
    
    guard let connection = self.videoDataOutput?.connection(with: .video),
          connection.isVideoOrientationSupported,
          connection.isVideoMirroringSupported
    else { return }
    if UIDevice.current.orientation == .portrait {
      connection.videoOrientation = .landscapeLeft
    } else {
      connection.videoOrientation = UIDevice.current.orientation.getVideoOrientation()
    }
    connection.automaticallyAdjustsVideoMirroring = true
    //    connection.isVideoMirrored = true // for .front
    //        connection.videoOrientation = .portrait
    
    
    audioDataOutput = AVCaptureAudioDataOutput()
    audioDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "audioQueue"))
    if captureSession.canAddOutput(audioDataOutput) {
      captureSession.addOutput(audioDataOutput)
    }
    
    previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
    //        previewLayer.connection?.videoOrientation = .portrait
    if UIDevice.current.orientation == .portrait {
      previewLayer.connection?.videoOrientation = .landscapeLeft
    } else {
      previewLayer.connection?.videoOrientation = UIDevice.current.orientation.getVideoOrientation()
    }
    previewLayer.frame = view.frame
    view.layer.insertSublayer(previewLayer, at: 0)
    
    
    
  }
  
  
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    captureSession.startRunning()
    
    
    startSending()
    isSending = true
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    captureSession.stopRunning()
  }
  
  private func startSending() {
    guard let ndiWrapper = self.ndi else { return }
    ndiWrapper.start("PivoCam")
    
    guard !isRecording else { return }
    isRecording = true
    sessionAtSourceTime = nil
  }
  
  private func stopSending() {
    guard let ndiWrapper = self.ndi else { return }
    ndiWrapper.stop()
    stop()
  }
  
  
  // MARK: Stop recording
  func stop() {
    guard isRecording else { return }
    isRecording = false
    captureSession.stopRunning()
  }
  
  
  public func getDimensionWith(preset:AVCaptureSession.Preset) -> CMVideoDimensions {
    if preset == .cif352x288 {
      return CMVideoDimensions(width: 352, height: 288)
    } else if preset == .vga640x480 {
      return CMVideoDimensions(width: 640, height: 480)
    } else if preset == .hd1920x1080 {
      return  CMVideoDimensions(width: 1920, height: 1080)
    } else if preset == .hd4K3840x2160 {
      return CMVideoDimensions(width: 3840, height: 2160)
    } else {
      return CMVideoDimensions(width: 1280, height: 720)
    }
  }
  public func getPresetWith(dimension:CMVideoDimensions) -> AVCaptureSession.Preset {
    if dimension.width >= 3840 && dimension.height >= 2160 {
      return .hd4K3840x2160
    } else if dimension.width >= 1920 && dimension.height >= 1080 {
      return .hd1920x1080
    } else if dimension.width >= 1280 && dimension.height >= 720 {
      return .hd1280x720
    } else if dimension.width >= 640 && dimension.height >= 480 {
      return .vga640x480
    } else if dimension.width <= 352 && dimension.height <= 288 {
      return .cif352x288
    } else {
      return .high
    }
  }
  
  func getSupportPreset(_ device:AVCaptureDevice, wantPreset:AVCaptureSession.Preset) -> AVCaptureSession.Preset {
    let wantDimension = getDimensionWith(preset: wantPreset)
    var supportDimension = CMVideoDimensions(width: 1280, height: 720)
    
    var supportFormat : AVCaptureDevice.Format? = nil
    for format in device.formats {
      let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
      if wantDimension.width >= dimensions.width && wantDimension.height >= dimensions.height {
        supportDimension = dimensions
        supportFormat = format
        if supportDimension.width >= wantDimension.width && supportDimension.height >= wantDimension.height {
          break
        }
      }
    }
    
    do {
      try device.lockForConfiguration()
    } catch {
      print("failed set deviceFormat")
      return getPresetWith(dimension: supportDimension)
    }
    // If the format is set to 1280x960, adding a VideoInput will automatically change it to 1280x720.
    device.activeFormat = supportFormat!
    device.unlockForConfiguration()
    print("[Streamer]  Support resulution : \(supportDimension)")
    return getPresetWith(dimension: supportDimension)
  }
  
  func getCameraMaxStillImageResolution(_ cameraPosition:AVCaptureDevice.Position) -> CMVideoDimensions {
    var videoDevice: AVCaptureDevice?
    videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition)
    var maxDimensions = CMVideoDimensions(width: 0, height: 0)
    guard let videoDevice = videoDevice else {
      return maxDimensions
    }
    
    for format in videoDevice.formats {
      let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
      
      print("Support dimension > \(dimensions)")
      if dimensions.width >= maxDimensions.width && dimensions.height >= maxDimensions.height {
        maxDimensions = dimensions
      }
    }
    return maxDimensions;
  }
  
  func printCamerasInfo() {
    var res:CMVideoDimensions
    res = self.getCameraMaxStillImageResolution(AVCaptureDevice.Position.back)
    print(" Back  Camera max Image resolution: \(res.width), \(res.height)")
    res = self.getCameraMaxStillImageResolution(AVCaptureDevice.Position.front)
    print(" Front Camera max Image resolution: \(res.width) , \(res.height)")
  }
  
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    
  }
  
  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    coordinator.animate(alongsideTransition: nil) { _ in
      self.previewLayer.connection?.videoOrientation = UIDevice.current.orientation.getVideoOrientation()
      var rect = self.view.bounds
      rect.size.width = size.width
      rect.size.height = size.height
      self.previewLayer.bounds = rect
      self.previewLayer.frame = rect
      print("previewLayer> \(rect)")
      self.view.frame = rect
      self.view.bounds = rect
    }
  }
  
  override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
  }
  
}

extension ViewController : AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate {
  
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    
    if output is AVCaptureVideoDataOutput {
      DispatchQueue.main.async {
        self.videoImageView.image = self.createImage(from: sampleBuffer)
      }
      
      
      guard let ndiWrapper = self.ndi, isSending else { return }
      guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
      ndiWrapper.sendVideo(pixelBuffer, withOrientation: Int32(UIDevice.current.orientation.getImageOrientation().rawValue))
      
      //            ndiWrapper.sendVideoAdv(sampleBuffer)
      
      print("b video ori > \(connection.videoOrientation.rawValue) UI > \(UIDevice.current.orientation.rawValue)")
      guard let connection = self.videoDataOutput?.connection(with: .video),
            connection.isVideoOrientationSupported,
            connection.isVideoMirroringSupported
      else { return }
      if connection.videoOrientation != UIDevice.current.orientation.getVideoOrientation() {
        connection.videoOrientation = UIDevice.current.orientation.getVideoOrientation()
      }
      print("a video ori > \(connection.videoOrientation.rawValue) UI > \(UIDevice.current.orientation.rawValue)")
      
    } else if output is AVCaptureAudioDataOutput {
      guard let ndiWrapper = self.ndi, isSending else { return }
      ndiWrapper.sendAudio(sampleBuffer)
    }
  }
  
  private func createImage(from sampleBuffer: CMSampleBuffer) -> UIImage? {
    guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
      return nil
    }
    
    let ciImage = CIImage(cvPixelBuffer: imageBuffer)
    let context = CIContext()
    
    guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
      return nil
    }
    
    return UIImage(cgImage: cgImage)
  }
  
  
}

extension UIDeviceOrientation {
  func getVideoOrientation() -> AVCaptureVideoOrientation {
    switch self {
    case .landscapeLeft:
      return .landscapeRight
    case .landscapeRight:
      return .landscapeLeft
    case .portrait:
      return .portrait
    case .portraitUpsideDown:
      return .portraitUpsideDown
    default:
      return .portrait
    }
  }
  // 이건 메인 이미지에 적용하면 안됨
  // mirror 은 고려해볼것..
  func getImageOrientation() -> UIImage.Orientation {
    return .up
    switch self {
    case .landscapeLeft:
      return .left//Mirrored
    case .landscapeRight:
      return .right//Mirrored
    case .portrait:
      return .upMirrored
    case .portraitUpsideDown:
      return .down
    default:
      return .up
    }
  }
}
