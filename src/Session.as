package
{

    import components.Console;

    import flash.net.*;
    import flash.events.*;
    import flash.utils.ByteArray;

    import mx.utils.UIDUtil;

    public class Session extends EventDispatcher
    {
        public static var DISCONNECT: String = "User_Disconnect";

        public var id: String;

        public var connected: Boolean;
        public var socket: Socket;
        public var data: Object;
        public var policy: Boolean;

        public function Session(socket: Socket): void
        {
            policy = false;
            connected = true;
            this.socket = socket;

            // Listen for the socket to close (a session disconnects)
            socket.addEventListener(Event.CLOSE, function (e: Event): void
            {
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
                }
                catch (error: Error)
                {
                    // If there's no object in the socket, assume it's a request for a policy file
                    // Respond with a policy file
                    socket.writeUTFBytes((new Service.POLICY() as ByteArray).toString());
                    socket.writeByte(0);
                    socket.flush();
                }

                // Set policy to true
                policy = true;
            });

            // Generate a session id
            id = UIDUtil.createUID();
            Console.log("Session (" + id + ") connected");
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
                    Console.log("Session (" + id + ") disconnected");
                    dispatchEvent(new Event(Session.DISCONNECT));
                }
            }
        }
    }
}