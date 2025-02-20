using Godot;

public partial class Player : CharacterBody2D
{
	[Signal]
	public delegate void CoinCollectedEventHandler();

	private const float WALK_SPEED = 300.0f;
	private const float ACCELERATION_SPEED = WALK_SPEED * 6.0f;
	private const float JUMP_VELOCITY = -125.0f;
	private const float TERMINAL_VELOCITY = 700.0f;
	private const float DRIFT_SPEED = 0.0f;
	private const float DRIFT_DIRECTION = 0.0f;
	//Typical volume of a fantail goldfish is 15in^3, .15kg, .02L (air sack), .25L (body)
	private const float airVolumeFull = 0.02f; //listed in Liters
	private const float airVolumeEmpty = 0.0f; //no air in air sack
	private const float bodyVolumeFull = 0.27f; //inlcudes air sack
	private const float bodyVolumeEmpty = 0.25f; //empty air sack

	[Export]
	public string ActionSuffix { get; set; } = "";

	private int gravity = 0;
	
	//(int)ProjectSettings.GetSetting("physics/2d/default_gravity");

	private RayCast2D platformDetector;
	private AnimationPlayer animationPlayer;
	private Timer shootTimer;
	private Sprite2D sprite;
	private AudioStreamPlayer2D jumpSound;
	private Node gun;
	private Camera2D camera;

	private bool _doubleJumpCharged = false;

	public override void _Ready()
	{
		GD.Print("Player script is running");
		platformDetector = GetNode<RayCast2D>("PlatformDetector");
		animationPlayer = GetNode<AnimationPlayer>("AnimationPlayer");
		shootTimer = GetNode<Timer>("ShootAnimation");
		sprite = GetNode<Sprite2D>("Sprite2D");
		jumpSound = GetNode<AudioStreamPlayer2D>("Jump");
		gun = sprite.GetNode("Gun");
		camera = GetNode<Camera2D>("Camera");
	}

	public override void _PhysicsProcess(double delta)
	{
		if (IsOnFloor())
		{
			_doubleJumpCharged = true;
		}

		if (Input.IsActionJustPressed("jump" + ActionSuffix))
		{
			TryInflate();
		}
		else if (Input.IsActionJustReleased("jump" + ActionSuffix) && Velocity.Y < 0.0f)
		{
			// Reduce vertical momentum if the jump button is released early
			//Velocity = new Vector2(Velocity.X, Velocity.Y * 0.6f);
		}
		if(Input.IsActionJustReleased("deflate" + ActionSuffix)){
			Velocity = new Vector2(Velocity.X, -JUMP_VELOCITY+Velocity.Y);
		}
		

		// Apply gravity and terminal velocity
		Velocity = new Vector2(Velocity.X, Mathf.Min(TERMINAL_VELOCITY, Velocity.Y + gravity * (float)delta));

		// Handle horizontal movement
		float direction = Input.GetAxis("move_left" + ActionSuffix, "move_right" + ActionSuffix) * WALK_SPEED;
		Velocity = new Vector2(Mathf.MoveToward(Velocity.X, direction, ACCELERATION_SPEED * (float)delta), Velocity.Y);

		// Flip sprite based on movement direction
		if (!Mathf.IsZeroApprox(Velocity.X))
		{
			sprite.Scale = new Vector2(Velocity.X > 0.0f ? 1.0f : -1.0f, sprite.Scale.Y);
		}

		FloorStopOnSlope = !platformDetector.IsColliding();
		MoveAndSlide();

		// Shooting logic
		bool isShooting = false;
		if (Input.IsActionJustPressed("shoot" + ActionSuffix))
		{
			isShooting = (bool)gun.Call("shoot", sprite.Scale.X);
		}

		// Animation handling
		string animation = GetNewAnimation(isShooting);
		if (animation != animationPlayer.CurrentAnimation && shootTimer.IsStopped())
		{
			if (isShooting)
			{
				shootTimer.Start();
			}
			animationPlayer.Play(animation);
		}
	}

	private string GetNewAnimation(bool isShooting = false)
	{
		string animationNew;
		if (IsOnFloor())
		{
			animationNew = Mathf.Abs(Velocity.X) > 0.1f ? "run" : "idle";
		}
		else
		{
			animationNew = Velocity.Y > 0.0f ? "falling" : "jumping";
		}

		if (isShooting)
		{
			animationNew += "_weapon";
		}

		return animationNew;
	}

	private void TryInflate()
	{
		// if (IsOnFloor())
		// {
		// 	jumpSound.PitchScale = 1.0f;
		// }
		// 		else if (_doubleJumpCharged)
		// 		{
		// 			_doubleJumpCharged = false;
		// 			Velocity = new Vector2(Velocity.X * 2.5f, Velocity.Y);
		// 			jumpSound.PitchScale = 1.5f;
		// 		}
		// 		
		// else
		// {
		// 	return;
		// }

		Velocity = new Vector2(Velocity.X, JUMP_VELOCITY+Velocity.Y);
		jumpSound.Play();
	}
}
