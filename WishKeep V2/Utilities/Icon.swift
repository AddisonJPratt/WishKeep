import SwiftUI

struct JarIcon: View {
    var size: CGFloat = 20
    var body: some View {
        if let ui = UIImage(named: "Icon_Jar") {
            Image(uiImage: ui)
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            Image(systemName: "archivebox")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        }
    }
}


