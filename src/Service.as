package
{

    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.geom.Matrix;

    /**
     * ...
     * @author Olin Kirkland
     */
    public class Service
    {
        // Port

        public static const PORT: int = 43699;

        // Icons

        [Embed(source="/assets/icons/chat.png")]
        public static const ICON_CHAT: Class;

        [Embed(source="/assets/icons/config.png")]
        public static const ICON_CONFIG: Class;

        [Embed(source="/assets/icons/speed.png")]
        public static const ICON_SPEED: Class;

        [Embed(source="/assets/icons/input.png")]
        public static const ICON_INPUT: Class;

        [Embed(source="/assets/icons/alert.png")]
        public static const ICON_ALERT: Class;

        [Embed(source="/assets/icons/email.png")]
        public static const ICON_EMAIL: Class;

        [Embed(source="/assets/icons/userJoined.png")]
        public static const ICON_USERJOINED: Class;

        [Embed(source="/assets/icons/userLeft.png")]
        public static const ICON_USERLEFT: Class;

        // Policy

        [Embed(source="/assets/policy.xml", mimeType="application/octet-stream")]
        public static var POLICY: Class;

        // Email

        [Embed(source="/assets/email/verify.html", mimeType="application/octet-stream")]
        public static var EMAIL_VERIFY: Class;

        [Embed(source="/assets/email/reset.html", mimeType="application/octet-stream")]
        public static var EMAIL_RESET: Class;

        // Image Storage

        public static var images: Object;

        public function Service(): void
        {
        }

        public static function getImage(name: String,
                                        width: int = -1,
                                        height: int = -1): Bitmap
        {
            images = (images) ? images : {};

            var imageId: String = name + "@" + width + "x" + height;
            if (!(width && height))
            {
                imageId = name;
            }

            if (!Service.images.hasOwnProperty(imageId))
            {
                var source: Bitmap = new Service[name];

                if (!(width && height))
                {
                    width = source.width;
                    height = source.height;
                }

                var mat: Matrix = new Matrix();
                mat.scale(width / source.width, height / source.height);
                var bmpd: BitmapData = new BitmapData(width,
                    height,
                    true,
                    0x00000000);

                bmpd.draw(source.bitmapData,
                    mat);

                images[imageId] = bmpd;
            }

            return new Bitmap(Service.images[imageId],
                "auto",
                true);
        }

        public static function isValidEmail(str: String): Boolean
        {
            // TODO redo this to allow all emails
            var emailExpression: RegExp = /([a-z0-9._-]+?)@([a-z0-9.-]+)\.([a-z]{2,4})/;
            return emailExpression.test(str);
        }

        public static function isValidName(str: String): Boolean
        {
            var nickExpression: RegExp = /[a-z0-9]*/;
            return nickExpression.test(str) && str.length >= 3 && str.length <= 16;
        }

        public static function generateRandomString(len: int): String
        {
            var dictionary: String = "abcdefghijklmnopqrstuvABCDEFGHIJKLMNOPQRSTUVXYZ0123456789";
            var str: String = "";
            for (var i: int = 0; i < len; i++)
                str += dictionary.charAt(int(Math.random() * dictionary.length));
            return str;
        }
    }
}