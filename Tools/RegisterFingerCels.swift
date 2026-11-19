// Asset measurement only: this tool never modifies sprite pixels.
// Run from the repository root: swift Tools/RegisterFingerCels.swift
import Cocoa
import Foundation
func measure(_ image: CGImage) -> [String:Double] {
    let w=image.width,h=image.height
    let cg=CGContext(data:nil,width:w,height:h,bitsPerComponent:8,bytesPerRow:w*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
    cg.draw(image,in:CGRect(x:0,y:0,width:w,height:h))
    let pixels=cg.data!.assumingMemoryBound(to:UInt8.self)
    func rgba(_ x:Int,_ y:Int)->(alphaComponent:Double,redComponent:Double,greenComponent:Double,blueComponent:Double) {
        let offset=(min(h-1,max(0,y))*w+min(w-1,max(0,x)))*4
        let a=Double(pixels[offset+3]);return (a/255,Double(pixels[offset])/max(1,a),Double(pixels[offset+1])/max(1,a),Double(pixels[offset+2])/max(1,a))
    }
    func bounds(_ y:Int)->(Int,Int)? {
        let xs=(0..<w).filter { rgba($0,y).alphaComponent > 0.85 }
        return xs.first.flatMap { first in xs.last.map { (first,$0) } }
    }
    let bottom=(0..<h).reversed().first { bounds($0) != nil }!
    let wristRow=bottom-max(5,h/40), b=bounds(wristRow)!, center=(b.0+b.1)/2
    var darkTop=wristRow
    while darkTop>0 {
        let c=rgba(center,darkTop-1)
        if c.alphaComponent < 0.85 || max(c.redComponent,c.greenComponent,c.blueComponent)>0.25 { break }
        darkTop-=1
    }
    func width(_ y:Int)->Double { guard let b=bounds(y) else { return 0 }; return Double(b.1-b.0+1) }
    var peakWidth=0.0, peakY=darkTop, neckY=darkTop
    for y in stride(from:min(bottom,darkTop+h/35),through:max(0,darkTop-h/4),by:-1) {
        let value=(-2...2).map { width(max(0,min(h-1,y+$0))) }.reduce(0,+)/5
        if value>peakWidth { peakWidth=value;peakY=y }
        if peakWidth>Double(w)*0.2 && y<peakY-h/60 && value<peakWidth*0.91 { neckY=y;break }
    }
    let top=(0..<h).first { width($0)>4 }!, tipBounds=bounds(top)!
    return ["width":Double(w),"center":Double(center),"opening":Double(darkTop),"cuffWidth":peakWidth,"cuffY":Double(peakY),"neck":Double(neckY),"bottom":Double(bottom),"tipX":Double(tipBounds.0+tipBounds.1)/2,"tipY":Double(top)]
}
var result=[String:[String:Double]]()
let root="Sources/Resources/Hands/"
for style in ["Classic","Witch"] {
    let base=NSImage(contentsOfFile:root+style+".png")!.cgImage(forProposedRect:nil,context:nil,hints:nil)!
    result[style]=measure(base)
    for page in ["A","B","C","D"] {
        let sheet=NSImage(contentsOfFile:root+"Idle/Frames/"+style+page+".png")!.cgImage(forProposedRect:nil,context:nil,hints:nil)!
        let size=sheet.width/2
        for i in 0..<4 {
            result[style+page+String(i)]=measure(sheet.cropping(to:CGRect(x:(i%2)*size,y:(i/2)*size,width:size,height:size))!)
        }
    }
}
let data=try JSONSerialization.data(withJSONObject:result,options:[.prettyPrinted,.sortedKeys])
try data.write(to:URL(fileURLWithPath:"Sources/Resources/Hands/Idle/Frames/Registration.json"))
print("Registered 32 whole hand cels in Sources/Resources/Hands/Idle/Frames/Registration.json")
