import Flutter
import UIKit
import MobileCoreServices
import ImageIO
import AVFoundation
import PDFKit


public class SwiftPdfMergerPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "pdf_merger", binaryMessenger: registrar.messenger())
    let instance = SwiftPdfMergerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
     if call.method == "mergeMultiplePDF" {
       if let args = call.arguments as? Dictionary<String, Any>{
        
        DispatchQueue.global().async {
            let singlePDFFromMultiplePDF =  SwiftPdfMergerPlugin.mergeMultiplePDF(args : args)
            DispatchQueue.main.sync {
                result(singlePDFFromMultiplePDF)
            }
        }
         } else {
             result("error")
         }
       } else if call.method == "createPDFFromMultipleImage" {
                     if let args = call.arguments as? Dictionary<String, Any>{

                        DispatchQueue.global().async {
                            let pdfFromMultipleImage = SwiftPdfMergerPlugin.createPDFFromMultipleImage(args : args)
                            DispatchQueue.main.sync {
                               result(pdfFromMultipleImage)
                            }
                        }
                       } else {
                           result("error")
                       }
      }else if call.method == "createImageFromPDF" {
                            if let args = call.arguments as? Dictionary<String, Any>{

                               DispatchQueue.global().async {
                                   let imageFromPDF = SwiftPdfMergerPlugin.createImageFromPDF(args : args)
                                   DispatchQueue.main.sync {
                                      result(imageFromPDF)
                                   }
                               }
                              } else {
                                  result("error")
                              }
    }else if call.method == "sizeForLocalFilePath" {
        if let args = call.arguments as? Dictionary<String, Any>{

           DispatchQueue.global().async {
               let sizeForFilePath = SwiftPdfMergerPlugin.sizeForLocalFilePath(args : args)
               DispatchQueue.main.sync {
                  result(sizeForFilePath)
               }
           }
          } else {
              result("error")
          }
}else if call.method == "buildDate" {

           let buildDateResponse = SwiftPdfMergerPlugin.buildDate()
           result(buildDateResponse)
}else if call.method == "buildDateWithTime" {
    
    let buildDateWithTimeResponse = SwiftPdfMergerPlugin.buildDateWithTime()
    result(buildDateWithTimeResponse)
}else if call.method == "versionName" {
    
    let versionNameResponse = SwiftPdfMergerPlugin.versionName()
    result(versionNameResponse)
}else if call.method == "versionCode" {
    
    let versionCodeResponse = SwiftPdfMergerPlugin.versionCode()
    result(versionCodeResponse)
}else if call.method == "packageName" {
    
    let packageNameResponse = SwiftPdfMergerPlugin.packageName()
    result(packageNameResponse)
}else if call.method == "appName" {
    
    let appNameResponse = SwiftPdfMergerPlugin.appName()
    result(appNameResponse)
} else{
            result("Not Implemented")
      }
  }

  class func mergeMultiplePDF(args: Dictionary<String, Any>) -> String? {

  do{

            if let paths = args["paths"] as? [String], let outputDirPath = args["outputDirPath"] as? String {
                
                let outPutDocument = PDFDocument()
                        
                for filePath in paths {
                    if let pdf = PDFDocument(url: URL(fileURLWithPath: filePath)) {
                        for p in 0..<pdf.pageCount {
                            let page = pdf.page(at: p)!
                            let copiedPage = page.copy() as! PDFPage // from docs
                            outPutDocument.insert(copiedPage, at: outPutDocument.pageCount)
                        }
                    }
                }
                outPutDocument.write(toFile: outputDirPath)
                return outputDirPath
             }

     } catch {
           return "error"
        }
          return "error"
  }




    class func createPDFFromMultipleImage(args: Dictionary<String, Any>) -> String? {

    do{

              if let paths = args["paths"] as? [String], let outputDirPath = args["outputDirPath"] as? String
               , let needImageCompressor = args["needImageCompressor"] as? Bool
                , let maxWidth = args["maxWidth"] as? Int
                 , let maxHeight = args["maxHeight"] as? Int{

                   guard UIGraphicsBeginPDFContextToFile(outputDirPath, CGRect.zero, nil) else {
                       return "error"
                   }


                    var images = [UIImage]()

                   for index in 0 ..< paths.count {
                      guard let  img  = UIImage(contentsOfFile: paths[index])  else { return "error" }

                      if(needImageCompressor){
                         let  resizedImage =  resizeImage(img : img,
                                                          maxWidthGet : maxWidth, maxHeightGet : maxHeight)
                          images.append(resizedImage)
                      }else{
                         images.append(img)
                      }
                    }

                  guard let  image = mergeVertically(images : images) else {  return "error" }


                  let pdfData = NSMutableData()
                  let imgView = UIImageView.init(image: image)
                  let imageRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
                  UIGraphicsBeginPDFContextToData(pdfData, imageRect, nil)
                  UIGraphicsBeginPDFPage()
                  let context = UIGraphicsGetCurrentContext()
                  imgView.layer.render(in: context!)
                  UIGraphicsEndPDFContext()


                  let urlOutputDirPath = URL.init(fileURLWithPath: outputDirPath)

                  do {
                     try pdfData.write(to: urlOutputDirPath, options: NSData.WritingOptions.atomic)
                  } catch {
                       return "error"
                  }


                  return outputDirPath
               }
                } catch {
                          return "error"
               }

            return "error"
    }



    class func createImageFromPDF(args: Dictionary<String, Any>) -> [String]? {

                                var pdfImagesPath = [String]()

        do{
              if let path = args["path"] as? String, let outputDirPath = args["outputDirPath"] as? String
               , let maxWidth = args["maxWidth"] as? Int
                               , let maxHeight = args["maxHeight"] as? Int
                                , let createOneImage = args["createOneImage"] as? Bool{

                   guard UIGraphicsBeginPDFContextToFile(outputDirPath, CGRect.zero, nil) else {
                       return nil
                   }
                
                                let pdfUrl = NSURL(fileURLWithPath: path)
                
                                let pdfDocument = CGPDFDocument(pdfUrl as CFURL)!
                                    let colorSpace = CGColorSpaceCreateDeviceRGB()
                                    let bitmapInfo = CGImageAlphaInfo.noneSkipLast.rawValue
                                var images = [UIImage]()
                
                                    DispatchQueue.concurrentPerform(iterations: pdfDocument.numberOfPages) { i in
                                        // Page number starts at 1, not 0
                                        let pdfPage = pdfDocument.page(at: i + 1)!

                                        let mediaBoxRect = pdfPage.getBoxRect(.mediaBox)
                                        let scale = 200 / 72.0
                                        let width = Int(mediaBoxRect.width * CGFloat(scale))
                                        let height = Int(mediaBoxRect.height * CGFloat(scale))

                                        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 16, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo)!
                                        context.interpolationQuality = .high
                                        context.setFillColor(UIColor.white.cgColor)
                                        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
                                        context.scaleBy(x: CGFloat(scale), y: CGFloat(scale))
                                        context.drawPDFPage(pdfPage)

                                        
                                        let image = context.makeImage()!
                                        
                                        let convertUIImage = UIImage(cgImage: image)
                                        
                                        let  resizeUIImage =  resizeImage(img : convertUIImage,
                                                                          maxWidthGet : maxWidth, maxHeightGet : maxHeight)


                                        images.append(resizeUIImage)

                                           if(!createOneImage){
                                            
                                           let pathName = outputDirPath.components(separatedBy: ".")
                                            
                                            let finalPath = pathName[0] + String(i) + "." + pathName[1]

                                              pdfImagesPath.append(finalPath)

                                            let urlOutputDirPath = NSURL(fileURLWithPath: finalPath)


                                            
                                               let imageDestination = CGImageDestinationCreateWithURL(urlOutputDirPath as CFURL,kUTTypePNG, 1, nil)!


                                               CGImageDestinationAddImage(imageDestination, resizeUIImage.cgImage ?? image, nil)
                                               CGImageDestinationFinalize(imageDestination)

                                           }
                                        

                                    }


                           if(createOneImage){
                                guard let  image = mergeVertically(images : images) else {  return nil }

                                 pdfImagesPath.append(outputDirPath)
                                let urlOutputDirPath = NSURL(fileURLWithPath: outputDirPath)

                                let imageDestination = CGImageDestinationCreateWithURL(urlOutputDirPath as CFURL,kUTTypePNG, 1, nil)!

                                guard let inputImage = image.cgImage else {  return nil }

                                CGImageDestinationAddImage(imageDestination, inputImage, nil)
                                CGImageDestinationFinalize(imageDestination)
                            }

                    return pdfImagesPath
               }

                } catch {
                   return nil
                }

            return nil
    }
    
    
    
    class func  sizeForLocalFilePath(args: Dictionary<String, Any>) -> String? {
        
        if let path = args["path"] as? String{

        do {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: path)
            if let fileSize = fileAttributes[FileAttributeKey.size]  {
                
                let unitFile = (fileSize as! NSNumber).uint64Value
                
                let  fileSizeString = covertToFileString(size : unitFile)
                
                return fileSizeString ?? "Error"
            } else {
                return "error"
            }
        } catch {
           return "error"
        }
        }
        
        return "error"
    }
    
    class func  buildDate() -> String? {
        
        if let executableURL = Bundle.main.executableURL,
            let creation = (try? executableURL.resourceValues(forKeys: [.creationDateKey]))?.creationDate {

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM/yyyy"
            return dateFormatter.string(from: creation)
        }
        
        return "error"
    }

    
    class func  buildDateWithTime() -> String? {
        
        if let executableURL = Bundle.main.executableURL,
            let creation = (try? executableURL.resourceValues(forKeys: [.creationDateKey]))?.creationDate {

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd-MM-yyyy HH:mm:ss"
            return dateFormatter.string(from: creation)
        }
        
        return "error"
    }

    
    class func  versionName() -> String? {
        
        if let appVersion =  Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            
            return appVersion
        }
        
        return "error"
    }

    
    class func  versionCode() -> String? {
        
        if let appVersionCode =  Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            
            return appVersionCode
        }
        
        return "error"
    }
    
    class func  packageName() -> String? {
        
        if let bundleID = Bundle.main.bundleIdentifier {
        
            return bundleID
        }
        
        return "error"
    }
    
    class func  appName() -> String? {
        
        if let appName = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String {
        
            return appName
        }
        
        return "error"
    }


    public static func mergeVertically(images: [UIImage]) -> UIImage? {

           var maxWidth:CGFloat = 0.0
            var maxHeight:CGFloat = 0.0


                     for image in images
                     {
                         maxHeight += image.size.height
                         if image.size.width > maxWidth
                         {
                             maxWidth = image.size.width
                         }
                     }

        let finalSize = CGSize(width: maxWidth, height: maxHeight)

         let frameSize: CGPoint = CGPoint(x: UIScreen.main.bounds.size.width*0.5,y: UIScreen.main.bounds.size.height*0.5)


           UIGraphicsBeginImageContext(finalSize)

           var runningHeight: CGFloat = 0.0

           for image in images
           {
               image.draw(in: CGRect(x: 0.0, y: runningHeight, width: image.size.width, height: image.size.height))
            runningHeight += image.size.height
           }

           let finalImage = UIGraphicsGetImageFromCurrentImageContext()

           UIGraphicsEndImageContext()

           return finalImage!
    }

    public static func resizeImage(img: UIImage, maxWidthGet : Int, maxHeightGet : Int) -> UIImage {
        var actualHeight: Float = Float(img.size.height)
        var actualWidth: Float = Float(img.size.width)
        let maxHeight: Float = Float(maxHeightGet)
        let maxWidth: Float = Float(maxWidthGet)
        var imgRatio: Float = actualWidth / actualHeight
        let maxRatio: Float = maxWidth / maxHeight
//        let compressionQuality: Float = 0.5
        //50 percent compression

        if actualHeight > maxHeight || actualWidth > maxWidth {
            if imgRatio < maxRatio {
                //adjust width according to maxHeight
                imgRatio = maxHeight / actualHeight
                actualWidth = imgRatio * actualWidth
                actualHeight = maxHeight
            }
            else if imgRatio > maxRatio {
                //adjust height according to maxWidth
                imgRatio = maxWidth / actualWidth
                actualHeight = imgRatio * actualHeight
                actualWidth = maxWidth
            }
            else {
                actualHeight = maxHeight
                actualWidth = maxWidth
            }
        }

        let rect = CGRect(x: 0.0, y: 0.0, width: CGFloat(actualWidth),  height: CGFloat(actualHeight))
    
        
        let newSize = AVMakeRect(
            aspectRatio: img.size,
            insideRect: rect
         ).size
        
//        UIGraphicsBeginImageContext(rect.size)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        img.draw(in: CGRect(origin: .zero, size: newSize))
        let scaled = UIGraphicsGetImageFromCurrentImageContext() ?? img
        UIGraphicsEndImageContext()
        
        
//        img.draw(in:rect)
//        let img = UIGraphicsGetImageFromCurrentImageContext()
//        let imageData = img?.jpegData(compressionQuality: CGFloat(compressionQuality))
//        UIGraphicsEndImageContext()
        return scaled
    }

    
    public static  func covertToFileString(size: UInt64) -> String? {
    do{
          var convertedValue: Double = Double(size)
          var multiplyFactor = 0
          let tokens = ["(bytes)", "(KB)", "(MB)", "(GB)", "(TB)", "(PB)",  "(EB)",  "(ZB)", "(YB)"]
          while convertedValue > 1024 {
              convertedValue /= 1024
              multiplyFactor += 1
          }
          return String(format: "%4.2f %@", convertedValue, tokens[multiplyFactor])
         } catch {
            return "error"
       }
  }
 
}
