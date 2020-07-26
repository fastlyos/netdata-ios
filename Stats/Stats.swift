//
//  Stats.swift
//  Stats
//
//  Created by Arjun Komath on 26/7/20.
//

import WidgetKit
import SwiftUI

public struct ServerData: Decodable {
    var labels: [String]
    var data: [[Double]]
}

struct ServerDataLoader {
    static func fetch(completion: @escaping (Result<ServerData, Error>) -> Void) {
        let branchContentsURL = URL(string: "https://netdata.code.techulus.com/api/v1/data?chart=system.cpu")!
        let task = URLSession.shared.dataTask(with: branchContentsURL) { (data, response, error) in
            guard error == nil else {
                completion(.failure(error!))
                return
            }
            let serverData = try? JSONDecoder().decode(ServerData.self, from: data!)
            completion(.success(serverData!))
        }
        task.resume()
    }
}

struct StatsTimeline: TimelineProvider {
    public typealias Entry = SimpleEntry
    
    public func snapshot(with context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), progress: 0)
        completion(entry)
    }
    
    public func timeline(with context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let refreshDate = Calendar.current.date(byAdding: .second, value: 10, to: currentDate)!
        
        ServerDataLoader.fetch { result in
            let serverData: ServerData
            if case .success(let fetchedServerData) = result {
                serverData = fetchedServerData
            } else {
                serverData = ServerData(labels: [], data: [])
            }
            
            let entry = SimpleEntry(date: currentDate, progress: CGFloat(Array(serverData.data.first![1..<serverData.data.first!.count]).reduce(0, +) / 100))
            let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
            completion(timeline)
        }
    }
}

struct SimpleEntry: TimelineEntry {
    public let date: Date
    public let progress: CGFloat
    
    var relevance: TimelineEntryRelevance? {
        return TimelineEntryRelevance(score: Float(progress * 100)) // 0 - not important | 100 - very important
    }
}

struct Meter : View {
    var progress: CGFloat
    var title: String
    var date: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            VStack(){
                ZStack {
                    Circle()
                        .stroke(lineWidth: 16.0)
                        .opacity(0.3)
                        .foregroundColor(self.getColor())
                    
                    Circle()
                        .trim(from: 0.0, to: CGFloat(min(self.progress, 1.0)))
                        .stroke(style: StrokeStyle(lineWidth: 17.0, lineCap: .round, lineJoin: .round))
                        .foregroundColor(self.getColor())
                        .rotationEffect(Angle(degrees: 270.0))
                        .animation(.linear)
                    
                    Text(String(format: "%.0f %%", min(self.progress, 1.0)*100.0))
                        .font(.caption)
                        .bold()
                }
                .frame(height: 72)
            }
            .padding(10)
            
            Text(date, style: .relative)
                .font(.system(.caption2))
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .leading)
        .padding()
    }
    
    func getColor() -> Color {
        if self.progress > 0.8 {
            return Color.red
        }
        
        if self.progress > 0.5 {
            return Color.blue
        }
        
        return Color.green
    }
}

struct StatsEntryView : View {
    var entry: StatsTimeline.Entry
    
    var body: some View {
        Meter(progress: entry.progress, title: "CPU Usage", date: entry.date)
    }
}

struct Stats_Previews: PreviewProvider {
    static var previews: some View {
        StatsEntryView(entry: SimpleEntry(date: Date(), progress: 0.2))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}


struct StatsEntryPlaceholderView : View {
    var body: some View {
        Meter(progress: 0.4, title: "CPU", date: Date())
            .redacted(reason: .placeholder)
    }
}

struct StatsPlaceholder_Previews: PreviewProvider {
    static var previews: some View {
        StatsEntryPlaceholderView()
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}

@main
struct Stats: Widget {
    private let kind: String = "NetData Stats"
    
    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind,
                            provider: StatsTimeline(),
                            placeholder: StatsEntryPlaceholderView()) { entry in
            StatsEntryView(entry: entry)
        }
        .configurationDisplayName("CPU Usage")
        .description("This is an example widget.")
    }
}