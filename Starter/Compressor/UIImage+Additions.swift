import UIKit
import AVFoundation

enum HEICError: Error {
  case heicNotSupported
  case cgImageMissing
  case couldNotFinalize
}

extension UIImage {
  func heicData(compressionQuality: CGFloat) throws -> Data {
    // To begin, you need an empty data buffer. Additionally, you create a destination for the HEIC encoded content using CGImageDestinationCreateWithData(_:_:_:_:). This method is part of the Image I/O framework and acts as a sort of container that can have image data added and its properties updated before writing the image data. If there is a problem here, HEIC isn’t available on the device.
    let data = NSMutableData()
    guard let imageDestination = CGImageDestinationCreateWithData(data, AVFileType.heic as CFString, 1, nil)
      else { throw HEICError.heicNotSupported }

    // You need to ensure there is image data to work with.
    guard let cgImage = self.cgImage
      else { throw HEICError.cgImageMissing }

    // The parameter passed into the method gets applied using the key kCGImageDestinationLossyCompressionQuality. You’re using the NSDictionary type since CoreGraphics requires it.
    let options: NSDictionary = [kCGImageDestinationLossyCompressionQuality: compressionQuality]

    // Finally, you apply the image data together with the options to the destination. CGImageDestinationFinalize(_:) finishes the HEIC image compression and returns true if it was successful.
    CGImageDestinationAddImage(imageDestination, cgImage, options)
    
    guard CGImageDestinationFinalize(imageDestination)
      else { throw HEICError.couldNotFinalize }

    return data as Data
  }
}
