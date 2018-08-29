package
{

    public class User
    {
        // Public
        public var name: String;
        public var id: String;
        public var coins: Number;
        public var tokens: Number;
        public var level: Number;
        public var experience: Number;
        public var experienceToNextLevel: Number;
        public var online: Boolean;

        // Private
        public var email: String;
        public var emailVerificationCode: String;
        public var emailVerified: Boolean;
        public var passwordResetCode: String;
        public var salt: String;
        public var password: String;

        public function User(obj: Object): void
        {

        }
    }
}