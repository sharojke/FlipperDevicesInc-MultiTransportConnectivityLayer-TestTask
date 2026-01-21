import Foundation

final class Router: ObservableObject {
    @Published var path = [Route]()
    
    func push(_ route: Route) {
        path.append(route)
    }
}
