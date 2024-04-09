/// Copyright (c) 2019 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit

class MainViewController: UIViewController {
  @IBOutlet var jpgSizeLabel: UILabel!
  @IBOutlet var jpgTimeLabel: UILabel!
  @IBOutlet var jpgActivityIndicator: UIActivityIndicatorView!
  @IBOutlet var jpgImageView: UIImageView!
  @IBOutlet var heicSizeLabel: UILabel!
  @IBOutlet var heicTimeLabel: UILabel!
  @IBOutlet var heicActivityIndicator: UIActivityIndicatorView!
  @IBOutlet var heicImageView: UIImageView!
  @IBOutlet var compressionSlider: UISlider!
  
  private let numberFormatter = NumberFormatter()
  private let compressionQueue = OperationQueue()
  private var previousQuality: Float = 0
  private var originalImage: UIImage = #imageLiteral(resourceName: "jeremy-thomas-unsplash")
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    title = "Compressor"
    
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      barButtonSystemItem: .add,
      target: self,
      action: #selector(addButtonPressed)
    )
    navigationItem.leftBarButtonItem = UIBarButtonItem(
      barButtonSystemItem: .action,
      target: self,
      action: #selector(shareButtonPressed)
    )
    
    compressionSlider.addTarget(
      self,
      action: #selector(sliderEndedTouch),
      for: [.touchUpInside, .touchUpOutside]
    )

    numberFormatter.maximumSignificantDigits = 1
    numberFormatter.maximumFractionDigits = 3
    
    updateImages()
  }
  
  // MARK: - Helpers
  
  private func resetLabels() {
    jpgSizeLabel.text = "--"
    jpgTimeLabel.text = "--"
    heicSizeLabel.text = "--"
    heicTimeLabel.text = "--"
  }
  
  private func elapsedTime(from startDate: Date) -> String? {
    let endDate = Date()
    let interval = endDate.timeIntervalSince(startDate)
    let intervalNumber = NSNumber(value: interval)
    
    return numberFormatter.string(from: intervalNumber)
  }
  
  private func compressJPGImage(with quality: CGFloat) {
    let startDate = Date()

    jpgImageView.image = nil
    jpgActivityIndicator.startAnimating()
    
    compressionQueue.addOperation {
      guard let data = self.originalImage.jpegData(compressionQuality: quality) else {
        return
      }
      
      DispatchQueue.main.async {
        if let time = self.elapsedTime(from: startDate) {
          self.jpgTimeLabel.text = "\(time) s"
        }
        self.jpgSizeLabel.text = data.prettySize
        self.jpgImageView.image = UIImage(data: data)
        self.navigationItem.leftBarButtonItem?.isEnabled = true
        
        UIView.animate(withDuration: 0.3) {
          self.jpgActivityIndicator.stopAnimating()
        }
      }
    }
  }
  
  private func compressHEICImage(with quality: CGFloat) {
    let startDate = Date()
    
    heicImageView.image = nil
    heicActivityIndicator.startAnimating()
    
    compressionQueue.addOperation {
      do {
        let data = try self.originalImage.heicData(compressionQuality: quality)
        
        DispatchQueue.main.async {
          if let time = self.elapsedTime(from: startDate) {
            self.heicTimeLabel.text = "\(time) s"
          }
          self.heicSizeLabel.text = data.prettySize
          self.heicImageView.image = UIImage(data: data)
          self.navigationItem.leftBarButtonItem?.isEnabled = true
          
          UIView.animate(withDuration: 0.3) {
            self.heicActivityIndicator.stopAnimating()
          }
        }
      } catch {
        print("Error creating HEIC data: \(error.localizedDescription)")
      }
    }
  }
  
  private func updateImages() {
    let quality = CGFloat(compressionSlider.value)
    
    resetLabels()
    compressionQueue.cancelAllOperations()
    navigationItem.leftBarButtonItem?.isEnabled = false
    
    compressJPGImage(with: quality)
    compressHEICImage(with: quality)
  }
  
  private func shareImage(_ image: UIImage) {
    let avc = UIActivityViewController(
      activityItems: [image],
      applicationActivities: nil
    )
    present(avc, animated: true)
  }
  
  // MARK: - Actions
  
  @objc private func addButtonPressed() {
    let picker = UIImagePickerController()
    picker.delegate = self
    
    present(picker, animated: true)
  }
  
  @objc private func shareButtonPressed() {
    let avc = UIAlertController(title: "Share", message: "How would you like to share?", preferredStyle: .alert)
    
    if let jpgImage = jpgImageView.image {
      avc.addAction(UIAlertAction(title: "JPG", style: .default) { _ in
        self.shareImage(jpgImage)
      })
    }
    
    if let heicImage = heicImageView.image {
      avc.addAction(UIAlertAction(title: "HEIC", style: .default) { _ in
        self.shareImage(heicImage)
      })
    }
    
    avc.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

    present(avc, animated: true)
  }
  
  @objc private func sliderEndedTouch() {
    updateImages()
  }
  
  @objc private func sliderDidChange() {
    let diff = abs(compressionSlider.value - previousQuality)
    
    guard diff > 0.1 else {
      return
    }
    
    previousQuality = compressionSlider.value
    
    updateImages()
  }
}

extension MainViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true)
  }
  
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    picker.dismiss(animated: true)

    guard let image = info[.originalImage] as? UIImage else {
      return
    }
    
    originalImage = image
    updateImages()
  }
}
