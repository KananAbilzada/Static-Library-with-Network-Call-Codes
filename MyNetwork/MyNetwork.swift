import UIKit

public enum HTTPMethod: String {
    case put = "PUT"
    case post = "POST"
    case get = "GET"
    case delete = "DELETE"
    case head = "HEAD"
}

public protocol Request {
    var scheme: String { get }
    var method: HTTPMethod { get }
    var path: String { get }
    var host: String { get }
    var queryItems: [URLQueryItem] { get }
    var headers: [String: String] { get }
    var body: Data? { get }
}

public extension Request {
    var scheme: String { return "https" }
    var method: HTTPMethod { return .get }
    var headers: [String: String] { return [:] }
    var body: Data? { return nil }
}

public extension Request {
    func build() -> URLRequest {
        var components = URLComponents()
        components.scheme     = scheme
        components.host       = host
        components.path       = path
        components.queryItems = queryItems
        guard let url = components.url else {
            preconditionFailure("Invalid url components")
        }
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = headers
        request.httpMethod          = method.rawValue
        request.httpBody            = body
        return request
    }
}

public struct DataLoader {
    public init () {}
    public func request<T: Decodable>(_ request: Request, decodable: T.Type,   then   handler: @escaping (Result<T, NetworkError>) -> Void) {
        
        let urlRequest = request.build()
        
        let urlSession = URLSession(configuration: .default)
        
        let task = urlSession.dataTask(with: urlRequest) {  data, urlResponse, error in
            if let e = error {
                handler(.failure(.cannotGetData))
                print(e.localizedDescription)
            } else {
                if let data = data {
                    do {
                        let decodedData = try decoder(with: data, decodable:    decodable)
                        handler(.success(decodedData))
                    } catch {
                        handler(.failure(.cannotDecode))
                    }
                } else {
                    handler(.failure(.cannotGetData))
                }
            }
            
        }
        task.resume()
    }
    
    // Decoder
    public func decoder<T: Decodable>(_ decoder: JSONDecoder =  JSONDecoder(), with data: Data, decodable: T.Type) throws -> T {
        
        let decodedData = try decoder.decode(T.self, from: data)
        return decodedData
    }
    
}
