package
{

    import br.com.stimuli.loading.BulkLoader;

    import flash.events.Event;
    import flash.events.EventDispatcher;

    public final class LocationManager extends EventDispatcher
    {
        private static var _instance: LocationManager;
        private var locations: BulkLoader;

        public function LocationManager()
        {
            if (_instance)
                throw new Error("Singleton; Use getInstance() instead");
            _instance = this;
        }

        public static function getInstance(): LocationManager
        {
            if (!_instance)
                new LocationManager();
            return _instance;
        }

        public function getLocation(ip: String): String
        {
            if (!locations)
                locations = new BulkLoader();

            if (locations.hasItem(ip))
            {
                // Return this location
                return locations.get(ip)["loader"].data as String;
            }
            else
            {
                // Get this location
                var url: String = "http://api.ipstack.com/" + ip + "?access_key=c93b08d638f3e76eee92dfd836eca885";
                locations.add(url, {id: ip});
                locations.get(ip).addEventListener(Event.COMPLETE, onItemComplete);

                locations.start();
            }

            return null;
        }

        public function onItemComplete(event: Event): void
        {
            event.target.removeEventListener(Event.COMPLETE, onItemComplete);
            dispatchEvent(new Event(Event.COMPLETE));
        }
    }
}
