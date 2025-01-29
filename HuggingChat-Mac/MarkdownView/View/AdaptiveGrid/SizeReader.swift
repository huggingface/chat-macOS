import SwiftUI

extension View {
    func sizeOfView(_ size: Binding<CGSize>) -> some View {
        modifier(_SizeReaderModifier(size: size))
    }
    
    func heightOfView(_ height: Binding<CGFloat>) -> some View {
        modifier(_HeightReaderModifier(height: height))
    }
    
    func widthOfView(_ width: Binding<CGFloat>) -> some View {
        modifier(_WidthReaderModifier(width: width))
    }
    
    @ViewBuilder func onSizeChange(_ action: @escaping (CGSize) -> Void) -> some View {
        let size = Binding<CGSize> {
            .zero
        } set: { newSize in
            action(newSize)
        }
        modifier(_SizeReaderModifier(size: size))
    }
    
    @ViewBuilder func onHeightChange(_ action: @escaping (CGFloat) -> Void) -> some View {
        let height = Binding<CGFloat> {
            .zero
        } set: { newHeight in
            action(newHeight)
        }
        modifier(_HeightReaderModifier(height: height))
    }
    
    @ViewBuilder func onWidthChange(_ action: @escaping (CGFloat) -> Void) -> some View {
        let width = Binding<CGFloat> {
            .zero
        } set: { newWidth in
            action(newWidth)
        }
        modifier(_WidthReaderModifier(width: width))
    }
}

fileprivate struct _SizeReaderModifier: ViewModifier {
    @Binding var size: CGSize
    
    func body(content: Content) -> some View {
        content
            ._overlay {
                GeometryReader { geometryProxy in
                    Color.clear
                        ._task(id: geometryProxy.size) {
                            size = geometryProxy.size
                        }
                }
            }
    }
}

fileprivate struct _HeightReaderModifier: ViewModifier {
    @Binding var height: CGFloat
    
    func body(content: Content) -> some View {
        content
            ._overlay {
                GeometryReader { geometryProxy in
                    Color.clear
                        ._task(id: geometryProxy.size) {
                            height = geometryProxy.size.height
                        }
                }
            }
    }
}

fileprivate struct _WidthReaderModifier: ViewModifier {
    @Binding var width: CGFloat
    
    func body(content: Content) -> some View {
        content
            ._overlay {
                GeometryReader { geometryProxy in
                    Color.clear
                        ._task(id: geometryProxy.size) {
                            width = geometryProxy.size.width
                        }
                }
            }
    }
}
