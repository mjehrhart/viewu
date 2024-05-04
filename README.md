# www.viewu.app
# installation.viewu.app
 
### Viewu App
**Platform:** iOS  
**Development Framework:** SwiftUI  
**Key Features:**
- **Notifications:** Users receive real-time alerts based on the object detections and other configured events from their Frigate NVR setup.
- **Timeline View:** Allows users to navigate through recorded footage with filtering options to quickly find events or specific times where detections occurred.
- **RTSP Viewing:** Enables real-time streaming protocol capabilities so users can watch live feeds directly from their cameras via the app.
- **Settings Menu:** Offers customization options for notifications, camera setup, detection preferences, and more, tailored to the user’s needs.

**Advantages of SwiftUI:**
- **Declarative Syntax:** Simplifies UI development with clear and concise code that describes the user interface components.
- **Live Previews:** Developers can see real-time previews of changes without running the app, speeding up the iterative design process.
- **Code Sharing and Automatic Layout:** Facilitates building UIs that work across all Apple devices with minimal adjustments, thanks to responsive and adaptive UI components that adjust to different screen sizes and environments.
- **Integration with Swift:** Offers seamless compatibility and optimization with Swift, making it efficient for building high-performance, responsive applications.

### Viewu Server
**Development Language:** Rust  
**Key Features:**
- Acts as a middleware or a backend server that interfaces with the Frigate NVR system, processing requests from the iOS app and forwarding commands or fetching video data as needed.

**Advantages of Rust:**
- **Safety and Performance:** Rust’s ownership model prevents common bugs (such as race conditions and memory leaks) without sacrificing performance, making it ideal for systems where reliability is critical.
- **Reliability:** Provides robust error handling which helps in building dependable applications that can run continuously without frequent crashes or memory issues.
- **Productivity with Type Safety:** Offers powerful developer tools and compiler-driven development which helps in catching errors early in the development cycle.
- **Cross-platform Compatibility:** Rust can be used to develop software for a wide range of operating systems and hardware, which is crucial for server applications that may need to run on diverse environments.

### Overall System Integration
By leveraging both SwiftUI and Rust, this setup aims to create a highly responsive, reliable, and user-friendly experience for iOS users looking to manage and interact with their Frigate NVR systems efficiently. The combination ensures a strong focus on both front-end usability and back-end stability, enhancing the security and convenience of home surveillance.
