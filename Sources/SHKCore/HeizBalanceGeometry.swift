import Foundation

public enum HeizBalanceGeometry {
    public static func floorArea(lengthM: Double, widthM: Double) -> Double {
        max(0, lengthM) * max(0, widthM)
    }

    public static func roomVolume(lengthM: Double, widthM: Double, heightM: Double) -> Double {
        floorArea(lengthM: lengthM, widthM: widthM) * max(0, heightM)
    }
}
