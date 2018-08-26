package
{

    import flash.events.Event;

    public class SessionEvent extends Event
    {
        public static var LOCATION_FOUND: String = "locationFound";

        public function SessionEvent(type: String)
        {
            super(type);
        }
    }
}
