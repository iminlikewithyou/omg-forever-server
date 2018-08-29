package
{

    import br.com.stimuli.loading.BulkLoader;

    import flash.events.EventDispatcher;

    public final class DataManager extends EventDispatcher
    {
        private static var _instance: DataManager;

        public function DataManager()
        {
            if (_instance)
                throw new Error("Singleton; Use getInstance() instead");
            _instance = this;
        }

        public static function getInstance(): DataManager
        {
            if (!_instance)
                new DataManager();
            return _instance;
        }

        public function getData(id: String): Object
        {
            return {};
        }
    }
}
