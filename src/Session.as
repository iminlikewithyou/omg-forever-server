package
{

    import components.Console;

    import flash.events.*;
    import flash.net.*;
    import flash.utils.ByteArray;

    import mx.utils.UIDUtil;

    public class Session extends EventDispatcher
    {
        public static var DISCONNECT: String = "User_Disconnect";

        private var locationManager: LocationManager;

        public var id: String;
        public var location: Object;
        public var ip: String;

        public var connected: Boolean;
        public var socket: Socket;
        public var data: Object;
        public var policy: Boolean;

        public function Session(socket: Socket): void
        {
            policy = false;
            connected = true;
            this.socket = socket;
            ip = socket.remoteAddress;

            // Listen for the socket to close (a session disconnects)

            socket.addEventListener(Event.CLOSE, function (e: Event): void
            {
                if (policy)
                    dispatchEvent(new Event(Session.DISCONNECT));
            });

            // Listen for data from the socket
            socket.addEventListener(ProgressEvent.SOCKET_DATA, function (e: ProgressEvent): void
            {
                try
                {
                    // Try to read an object from the socket
                    data = socket.readObject();
                    socket.flush();
                    dispatchEvent(new MessageEvent(data));

                    // Set policy to true
                    policy = true;
                    Console.log("Session (" + id + ") connected\n  " + socket.remoteAddress, "userJoined", {ip: socket.remoteAddress});
                }
                catch (error: Error)
                {
                    // If there's no object in the socket, assume it's a request for a policy file
                    // Respond with a policy file
                    socket.writeUTFBytes((new Service.POLICY() as ByteArray).toString());
                    socket.writeByte(0);
                    socket.flush();
                }
            });

            // Generate a session id
            id = UIDUtil.createUID();

            locationManager = LocationManager.getInstance();
            location = locationManager.getLocation(ip);
            if (!location)
                locationManager.addEventListener(Event.COMPLETE, getLocationAgain);
        }

        private function getLocationAgain(event: Event): void
        {
            location = locationManager.getLocation(ip);
            if (location)
            {
                locationManager.removeEventListener(Event.COMPLETE, getLocationAgain);
                dispatchEvent(new SessionEvent(SessionEvent.LOCATION_FOUND));
            }
        }

        public function send(data: Object): void
        {
            if (connected)
            {
                try
                {
                    // Try to send an object to the socket
                    socket.writeObject(data);
                    socket.flush();
                }
                catch (error: Error)
                {
                    // There's no connection, or there was a problem with the connection
                    // Disconnect this socket and don't try to send any more messages to it
                    connected = false;
                    dispatchEvent(new Event(Session.DISCONNECT));
                }
            }
        }
    }
}