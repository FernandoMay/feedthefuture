use anchor_lang::prelude::*;
use anchor_spl::token::{Mint, Token};

declare_id!("F1T3F11111111111111111111111111111111111111");

#[program]
pub mod feed_the_future {
    use super::*;

    // ==================== USER MANAGEMENT ====================

    /// Initialize a new user with role and profile
    pub fn initialize_user(
        ctx: Context<InitializeUser>,
        role: UserRole,
        username: String,
        email: String,
        location: Location,
    ) -> Result<()> {
        let user = &mut ctx.accounts.user;
        let clock = Clock::get()?;

        user.authority = ctx.accounts.authority.key();
        user.role = role.clone();
        user.username = username;
        user.email = email;
        user.location = location;
        user.reputation_score = 100; // Start with neutral reputation
        user.total_donations = 0;
        user.total_pickups = 0;
        user.total_deliveries = 0;
        user.is_verified = false;
        user.is_active = true;
        user.created_at = clock.unix_timestamp;
        user.updated_at = clock.unix_timestamp;
        user.bump = ctx.bumps.user;

        emit!(UserCreated {
            user: user.key(),
            authority: ctx.accounts.authority.key(),
            role: role.clone(),
            timestamp: clock.unix_timestamp,
        });

        Ok(())
    }

    /// Update user profile information
    pub fn update_user_profile(
        ctx: Context<UpdateUserProfile>,
        username: Option<String>,
        email: Option<String>,
        location: Option<Location>,
    ) -> Result<()> {
        let user = &mut ctx.accounts.user;
        let clock = Clock::get()?;

        if let Some(username) = username {
            user.username = username;
        }
        if let Some(email) = email {
            user.email = email;
        }
        if let Some(location) = location {
            user.location = location;
        }

        user.updated_at = clock.unix_timestamp;

        emit!(UserProfileUpdated {
            user: user.key(),
            timestamp: clock.unix_timestamp,
        });

        Ok(())
    }

    /// Verify a user (admin only)
    pub fn verify_user(ctx: Context<VerifyUser>) -> Result<()> {
        let user = &mut ctx.accounts.user;
        let clock = Clock::get()?;

        require!(user.is_active, CustomError::UserInactive);
        require!(!user.is_verified, CustomError::UserAlreadyVerified);

        user.is_verified = true;
        user.updated_at = clock.unix_timestamp;

        emit!(UserVerified {
            user: user.key(),
            verified_by: ctx.accounts.authority.key(),
            timestamp: clock.unix_timestamp,
        });

        Ok(())
    }

    // ==================== DONATION MANAGEMENT ====================

    /// Create a new donation
    pub fn create_donation(
        ctx: Context<CreateDonation>,
        donation_data: DonationData,
    ) -> Result<()> {
        let donation = &mut ctx.accounts.donation;
        let clock = Clock::get()?;

        donation.donor = ctx.accounts.donor.key();
        donation.donation_data = donation_data.clone();
        donation.status = DonationStatus::Available;
        donation.risk_score = RiskScore::Safe;
        donation.matched_ngo = None;
        donation.pickup_volunteer = None;
        donation.delivery_volunteer = None;
        donation.pickup_scheduled_at = None;
        donation.delivery_scheduled_at = None;
        donation.created_at = clock.unix_timestamp;
        donation.updated_at = clock.unix_timestamp;
        donation.bump = ctx.bumps.donation;

        // Update donor stats
        let donor_account = &mut ctx.accounts.donor_account;
        donor_account.total_donations += 1;
        donor_account.updated_at = clock.unix_timestamp;

        emit!(DonationCreated {
            donation: donation.key(),
            donor: ctx.accounts.donor.key(),
            category: donation_data.category.clone(),
            quantity: donation_data.quantity,
            timestamp: clock.unix_timestamp,
        });

        Ok(())
    }

    /// Match donation with NGO
    pub fn match_donation(
        ctx: Context<MatchDonation>,
        ngo_pda: Pubkey,
    ) -> Result<()> {
        let donation = &mut ctx.accounts.donation;
        let clock = Clock::get()?;

        require!(
            donation.status == DonationStatus::Available,
            CustomError::DonationNotAvailable
        );

        donation.status = DonationStatus::Matched;
        donation.matched_ngo = Some(ngo_pda);
        donation.updated_at = clock.unix_timestamp;

        emit!(DonationMatched {
            donation: donation.key(),
            ngo: ngo_pda,
            timestamp: clock.unix_timestamp,
        });

        Ok(())
    }

    /// Schedule pickup for donation
    pub fn schedule_pickup(
        ctx: Context<SchedulePickup>,
        pickup_time: i64,
        pickup_location: Location,
    ) -> Result<()> {
        let donation = &mut ctx.accounts.donation;
        let clock = Clock::get()?;

        require!(
            donation.status == DonationStatus::Matched,
            CustomError::DonationNotMatched
        );

        donation.status = DonationStatus::Pending;
        donation.pickup_volunteer = Some(ctx.accounts.volunteer.key());
        donation.pickup_scheduled_at = Some(pickup_time);
        donation.updated_at = clock.unix_timestamp;

        // Create pickup request
        let pickup_request = &mut ctx.accounts.pickup_request;
        pickup_request.donation = donation.key();
        pickup_request.volunteer = ctx.accounts.volunteer.key();
        pickup_request.scheduled_time = pickup_time;
        pickup_request.location = pickup_location;
        pickup_request.status = PickupStatus::Scheduled;
        pickup_request.created_at = clock.unix_timestamp;
        pickup_request.bump = ctx.bumps.pickup_request;

        // Update volunteer stats
        let volunteer_account = &mut ctx.accounts.volunteer_account;
        volunteer_account.total_pickups += 1;
        volunteer_account.updated_at = clock.unix_timestamp;

        emit!(PickupScheduled {
            donation: donation.key(),
            volunteer: ctx.accounts.volunteer.key(),
            scheduled_time: pickup_time,
            timestamp: clock.unix_timestamp,
        });

        Ok(())
    }

    /// Complete pickup and start delivery
    pub fn complete_pickup(
        ctx: Context<CompletePickup>,
        actual_quantity: u64,
        notes: Option<String>,
    ) -> Result<()> {
        let donation = &mut ctx.accounts.donation;
        let pickup_request = &mut ctx.accounts.pickup_request;
        let clock = Clock::get()?;

        require!(
            pickup_request.status == PickupStatus::Scheduled,
            CustomError::PickupNotScheduled
        );

        donation.status = DonationStatus::InTransit;
        donation.donation_data.quantity = actual_quantity;
        donation.updated_at = clock.unix_timestamp;

        pickup_request.status = PickupStatus::Completed;
        pickup_request.completed_at = Some(clock.unix_timestamp);
        pickup_request.notes = notes;

        emit!(PickupCompleted {
            donation: donation.key(),
            volunteer: ctx.accounts.volunteer.key(),
            actual_quantity,
            timestamp: clock.unix_timestamp,
        });

        Ok(())
    }

    /// Schedule delivery
    pub fn schedule_delivery(
        ctx: Context<ScheduleDelivery>,
        delivery_time: i64,
        delivery_location: Location,
    ) -> Result<()> {
        let donation = &mut ctx.accounts.donation;
        let clock = Clock::get()?;

        require!(
            donation.status == DonationStatus::InTransit,
            CustomError::DonationNotInTransit
        );

        donation.delivery_volunteer = Some(ctx.accounts.volunteer.key());
        donation.delivery_scheduled_at = Some(delivery_time);
        donation.updated_at = clock.unix_timestamp;

        // Create delivery request
        let delivery_request = &mut ctx.accounts.delivery_request;
        delivery_request.donation = donation.key();
        delivery_request.volunteer = ctx.accounts.volunteer.key();
        delivery_request.scheduled_time = delivery_time;
        delivery_request.location = delivery_location;
        delivery_request.status = DeliveryStatus::Scheduled;
        delivery_request.created_at = clock.unix_timestamp;
        delivery_request.bump = ctx.bumps.delivery_request;

        // Update volunteer stats
        let volunteer_account = &mut ctx.accounts.volunteer_account;
        volunteer_account.total_deliveries += 1;
        volunteer_account.updated_at = clock.unix_timestamp;

        emit!(DeliveryScheduled {
            donation: donation.key(),
            volunteer: ctx.accounts.volunteer.key(),
            scheduled_time: delivery_time,
            timestamp: clock.unix_timestamp,
        });

        Ok(())
    }

    /// Complete delivery
    pub fn complete_delivery(
        ctx: Context<CompleteDelivery>,
        received_quantity: u64,
        confirmation_photo_url: Option<String>,
        notes: Option<String>,
    ) -> Result<()> {
        let donation = &mut ctx.accounts.donation;
        let delivery_request = &mut ctx.accounts.delivery_request;
        let clock = Clock::get()?;

        require!(
            delivery_request.status == DeliveryStatus::Scheduled,
            CustomError::DeliveryNotScheduled
        );

        donation.status = DonationStatus::Delivered;
        donation.donation_data.quantity = received_quantity;
        donation.updated_at = clock.unix_timestamp;

        delivery_request.status = DeliveryStatus::Completed;
        delivery_request.completed_at = Some(clock.unix_timestamp);
        delivery_request.confirmation_photo_url = confirmation_photo_url;
        delivery_request.notes = notes;

        // Update reputation scores
        let donor_account = &mut ctx.accounts.donor_account;
        donor_account.reputation_score = donor_account.reputation_score.saturating_add(5);

        let volunteer_account = &mut ctx.accounts.volunteer_account;
        volunteer_account.reputation_score = volunteer_account.reputation_score.saturating_add(3);

        emit!(DeliveryCompleted {
            donation: donation.key(),
            volunteer: ctx.accounts.volunteer.key(),
            received_quantity,
            timestamp: clock.unix_timestamp,
        });

        Ok(())
    }

    // ==================== REPUTATION & REWARDS ====================

    /// Update user reputation
    pub fn update_reputation(
        ctx: Context<UpdateReputation>,
        target_user: Pubkey,
        reputation_change: i16,
        reason: String,
    ) -> Result<()> {
        let user_account = &mut ctx.accounts.target_user_account;
        let clock = Clock::get()?;

        let new_score = user_account.reputation_score as i32 + reputation_change as i32;
        require!(new_score >= 0 && new_score <= 1000, CustomError::InvalidReputationScore);
        
        user_account.reputation_score = new_score as u16;
        user_account.updated_at = clock.unix_timestamp;

        emit!(ReputationUpdated {
            user: target_user,
            updated_by: ctx.accounts.authority.key(),
            new_score: user_account.reputation_score,
            change: reputation_change,
            reason,
            timestamp: clock.unix_timestamp,
        });

        Ok(())
    }

    /// Create reward token for user
    pub fn create_reward_token(
        ctx: Context<CreateRewardToken>,
        _token_name: String,
        _token_symbol: String,
        _token_uri: String,
    ) -> Result<()> {
        let user = &ctx.accounts.user;
        let clock = Clock::get()?;
        
        // For now, just emit the event - metadata creation can be done client-side
        // or in a separate transaction to avoid complexity
        
        emit!(RewardTokenCreated {
            mint: ctx.accounts.mint.key(),
            user: user.authority,
            timestamp: clock.unix_timestamp,
        });

        Ok(())
    }

    // ==================== ADMIN FUNCTIONS ====================

    /// Initialize global configuration
    pub fn initialize_config(
        ctx: Context<InitializeConfig>,
        config: GlobalConfig,
    ) -> Result<()> {
        let global_config = &mut ctx.accounts.global_config;
        let clock = Clock::get()?;

        global_config.authority = ctx.accounts.authority.key();
        global_config.config = config;
        global_config.created_at = clock.unix_timestamp;
        global_config.updated_at = clock.unix_timestamp;
        global_config.bump = ctx.bumps.global_config;

        emit!(ConfigInitialized {
            authority: ctx.accounts.authority.key(),
            timestamp: clock.unix_timestamp,
        });

        Ok(())
    }

    /// Update global configuration (admin only)
    pub fn update_config(
        ctx: Context<UpdateConfig>,
        new_config: GlobalConfig,
    ) -> Result<()> {
        let global_config = &mut ctx.accounts.global_config;
        let clock = Clock::get()?;

        global_config.config = new_config;
        global_config.updated_at = clock.unix_timestamp;

        emit!(ConfigUpdated {
            authority: ctx.accounts.authority.key(),
            timestamp: clock.unix_timestamp,
        });

        Ok(())
    }
}

// ==================== ACCOUNTS ====================

#[derive(Accounts)]
#[instruction(role: UserRole)]
pub struct InitializeUser<'info> {
    #[account(
        init,
        payer = authority,
        space = 8 + UserAccount::INIT_SPACE,
        seeds = [b"user", authority.key().as_ref()],
        bump
    )]
    pub user: Account<'info, UserAccount>,
    
    #[account(mut)]
    pub authority: Signer<'info>,
    
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct UpdateUserProfile<'info> {
    #[account(
        mut,
        seeds = [b"user", user.authority.as_ref()],
        bump = user.bump,
        has_one = authority
    )]
    pub user: Account<'info, UserAccount>,
    
    pub authority: Signer<'info>,
}

#[derive(Accounts)]
pub struct VerifyUser<'info> {
    #[account(
        mut,
        seeds = [b"user", user.authority.as_ref()],
        bump = user.bump
    )]
    pub user: Account<'info, UserAccount>,
    
    #[account(
        seeds = [b"user", authority.key().as_ref()],
        bump = authority_user.bump,
        constraint = authority_user.role == UserRole::Admin @ CustomError::Unauthorized
    )]
    pub authority_user: Account<'info, UserAccount>,
    
    pub authority: Signer<'info>,
}

#[derive(Accounts)]
#[instruction(donation_data: DonationData)]
pub struct CreateDonation<'info> {
    #[account(
        init,
        payer = donor,
        space = 8 + Donation::INIT_SPACE,
        seeds = [b"donation", donor.key().as_ref(), &Clock::get().unwrap().unix_timestamp.to_le_bytes()],
        bump
    )]
    pub donation: Account<'info, Donation>,
    
    #[account(
        mut,
        seeds = [b"user", donor.key().as_ref()],
        bump = donor_account.bump,
        constraint = donor_account.role == UserRole::Donor || donor_account.role == UserRole::Admin @ CustomError::InvalidRole
    )]
    pub donor_account: Account<'info, UserAccount>,
    
    #[account(mut)]
    pub donor: Signer<'info>,
    
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct MatchDonation<'info> {
    #[account(
        mut,
        seeds = [b"donation", donation.donor.as_ref(), &donation.created_at.to_le_bytes()],
        bump = donation.bump
    )]
    pub donation: Account<'info, Donation>,
    
    #[account(
        seeds = [b"user", ngo.key().as_ref()],
        bump = ngo_user.bump,
        constraint = ngo_user.role == UserRole::Ngo || ngo_user.role == UserRole::Admin @ CustomError::InvalidRole
    )]
    pub ngo_user: Account<'info, UserAccount>,
    
    pub ngo: Signer<'info>,
}

#[derive(Accounts)]
pub struct SchedulePickup<'info> {
    #[account(
        mut,
        seeds = [b"donation", donation.donor.as_ref(), &donation.created_at.to_le_bytes()],
        bump = donation.bump
    )]
    pub donation: Account<'info, Donation>,
    
    #[account(
        init,
        payer = volunteer,
        space = 8 + PickupRequest::INIT_SPACE,
        seeds = [b"pickup", donation.key().as_ref()],
        bump
    )]
    pub pickup_request: Account<'info, PickupRequest>,
    
    #[account(
        mut,
        seeds = [b"user", volunteer.key().as_ref()],
        bump = volunteer_account.bump,
        constraint = volunteer_account.role == UserRole::Volunteer || volunteer_account.role == UserRole::Admin @ CustomError::InvalidRole
    )]
    pub volunteer_account: Account<'info, UserAccount>,
    
    #[account(mut)]
    pub volunteer: Signer<'info>,
    
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct CompletePickup<'info> {
    #[account(
        mut,
        seeds = [b"donation", donation.donor.as_ref(), &donation.created_at.to_le_bytes()],
        bump = donation.bump
    )]
    pub donation: Account<'info, Donation>,
    
    #[account(
        mut,
        seeds = [b"pickup", donation.key().as_ref()],
        bump = pickup_request.bump,
        constraint = pickup_request.volunteer == volunteer.key() @ CustomError::Unauthorized
    )]
    pub pickup_request: Account<'info, PickupRequest>,
    
    #[account(
        seeds = [b"user", volunteer.key().as_ref()],
        bump = volunteer_account.bump
    )]
    pub volunteer_account: Account<'info, UserAccount>,
    
    pub volunteer: Signer<'info>,
}

#[derive(Accounts)]
pub struct ScheduleDelivery<'info> {
    #[account(
        mut,
        seeds = [b"donation", donation.donor.as_ref(), &donation.created_at.to_le_bytes()],
        bump = donation.bump
    )]
    pub donation: Account<'info, Donation>,
    
    #[account(
        init,
        payer = volunteer,
        space = 8 + DeliveryRequest::INIT_SPACE,
        seeds = [b"delivery", donation.key().as_ref()],
        bump
    )]
    pub delivery_request: Account<'info, DeliveryRequest>,
    
    #[account(
        mut,
        seeds = [b"user", volunteer.key().as_ref()],
        bump = volunteer_account.bump,
        constraint = volunteer_account.role == UserRole::Volunteer || volunteer_account.role == UserRole::Admin @ CustomError::InvalidRole
    )]
    pub volunteer_account: Account<'info, UserAccount>,
    
    #[account(mut)]
    pub volunteer: Signer<'info>,
    
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct CompleteDelivery<'info> {
    #[account(
        mut,
        seeds = [b"donation", donation.donor.as_ref(), &donation.created_at.to_le_bytes()],
        bump = donation.bump
    )]
    pub donation: Account<'info, Donation>,
    
    #[account(
        mut,
        seeds = [b"delivery", donation.key().as_ref()],
        bump = delivery_request.bump,
        constraint = delivery_request.volunteer == volunteer.key() @ CustomError::Unauthorized
    )]
    pub delivery_request: Account<'info, DeliveryRequest>,
    
    #[account(
        mut,
        seeds = [b"user", donation.donor.as_ref()],
        bump = donor_account.bump
    )]
    pub donor_account: Account<'info, UserAccount>,
    
    #[account(
        seeds = [b"user", volunteer.key().as_ref()],
        bump = volunteer_account.bump
    )]
    pub volunteer_account: Account<'info, UserAccount>,
    
    pub volunteer: Signer<'info>,
}

#[derive(Accounts)]
#[instruction(target_user: Pubkey)]
pub struct UpdateReputation<'info> {
    #[account(
        mut,
        seeds = [b"user", target_user.as_ref()],
        bump = target_user_account.bump
    )]
    pub target_user_account: Account<'info, UserAccount>,
    
    #[account(
        seeds = [b"user", authority.key().as_ref()],
        bump = authority_user.bump,
        constraint = authority_user.role == UserRole::Admin @ CustomError::Unauthorized
    )]
    pub authority_user: Account<'info, UserAccount>,
    
    pub authority: Signer<'info>,
}

#[derive(Accounts)]
#[instruction(token_name: String, token_symbol: String, token_uri: String)]
pub struct CreateRewardToken<'info> {
    #[account(
        seeds = [b"user", user.authority.as_ref()],
        bump = user.bump
    )]
    pub user: Account<'info, UserAccount>,
    
    #[account(
        init,
        payer = authority,
        mint::decimals = 0,
        mint::authority = authority.key(),
        seeds = [b"reward", user.authority.as_ref(), token_name.as_bytes()],
        bump
    )]
    pub mint: Account<'info, Mint>,
    
    #[account(mut)]
    pub authority: Signer<'info>,
    
    pub system_program: Program<'info, System>,
    pub token_program: Program<'info, Token>,
    pub rent: Sysvar<'info, Rent>,
}

#[derive(Accounts)]
#[instruction(config: GlobalConfig)]
pub struct InitializeConfig<'info> {
    #[account(
        init,
        payer = authority,
        space = 8 + GlobalConfigAccount::INIT_SPACE,
        seeds = [b"config"],
        bump
    )]
    pub global_config: Account<'info, GlobalConfigAccount>,
    
    #[account(mut)]
    pub authority: Signer<'info>,
    
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct UpdateConfig<'info> {
    #[account(
        mut,
        seeds = [b"config"],
        bump = global_config.bump,
        has_one = authority
    )]
    pub global_config: Account<'info, GlobalConfigAccount>,
    
    pub authority: Signer<'info>,
}

// ==================== DATA STRUCTURES ====================

#[account]
#[derive(InitSpace)]
pub struct UserAccount {
    pub authority: Pubkey,
    pub role: UserRole,
    #[max_len(50)]
    pub username: String,
    #[max_len(100)]
    pub email: String,
    pub location: Location,
    pub reputation_score: u16,
    pub total_donations: u32,
    pub total_pickups: u32,
    pub total_deliveries: u32,
    pub is_verified: bool,
    pub is_active: bool,
    pub created_at: i64,
    pub updated_at: i64,
    pub bump: u8,
}

#[account]
#[derive(InitSpace)]
pub struct Donation {
    pub donor: Pubkey,
    pub donation_data: DonationData,
    pub status: DonationStatus,
    pub risk_score: RiskScore,
    pub matched_ngo: Option<Pubkey>,
    pub pickup_volunteer: Option<Pubkey>,
    pub delivery_volunteer: Option<Pubkey>,
    pub pickup_scheduled_at: Option<i64>,
    pub delivery_scheduled_at: Option<i64>,
    pub created_at: i64,
    pub updated_at: i64,
    pub bump: u8,
}

#[account]
#[derive(InitSpace)]
pub struct PickupRequest {
    pub donation: Pubkey,
    pub volunteer: Pubkey,
    pub scheduled_time: i64,
    pub location: Location,
    pub status: PickupStatus,
    pub completed_at: Option<i64>,
    #[max_len(500)]
    pub notes: Option<String>,
    pub created_at: i64,
    pub bump: u8,
}

#[account]
#[derive(InitSpace)]
pub struct DeliveryRequest {
    pub donation: Pubkey,
    pub volunteer: Pubkey,
    pub scheduled_time: i64,
    pub location: Location,
    pub status: DeliveryStatus,
    pub completed_at: Option<i64>,
    #[max_len(500)]
    pub confirmation_photo_url: Option<String>,
    #[max_len(500)]
    pub notes: Option<String>,
    pub created_at: i64,
    pub bump: u8,
}

#[account]
#[derive(InitSpace)]
pub struct GlobalConfigAccount {
    pub authority: Pubkey,
    pub config: GlobalConfig,
    pub created_at: i64,
    pub updated_at: i64,
    pub bump: u8,
}

#[derive(AnchorSerialize, AnchorDeserialize, Clone, InitSpace)]
pub struct Location {
    pub latitude: f64,
    pub longitude: f64,
    #[max_len(200)]
    pub address: String,
    #[max_len(100)]
    pub city: String,
    #[max_len(50)]
    pub state: String,
    #[max_len(20)]
    pub postal_code: String,
    #[max_len(50)]
    pub country: String,
}

#[derive(AnchorSerialize, AnchorDeserialize, Clone, InitSpace)]
pub struct DonationData {
    #[max_len(100)]
    pub name: String,
    #[max_len(50)]
    pub category: String,
    pub quantity: u64,
    #[max_len(20)]
    pub unit: String,
    #[max_len(500)]
    pub description: String,
    #[max_len(10)]
    pub expiration_date: String,
    #[max_len(500)]
    pub storage_requirements: String,
    pub is_urgent: bool,
    pub is_perishable: bool,
    pub requires_refrigeration: bool,
    #[max_len(1000)]
    pub images: Vec<String>,
}

#[derive(AnchorSerialize, AnchorDeserialize, Clone, InitSpace)]
pub struct GlobalConfig {
    pub min_reputation_for_matching: u16,
    pub max_donations_per_day: u32,
    pub pickup_timeout_hours: u32,
    pub delivery_timeout_hours: u32,
    pub reputation_decay_rate: u16,
    pub reward_token_amount_per_donation: u64,
    pub co2_saved_per_kg: u64,
    pub platform_fee_percentage: u16,
    pub emergency_threshold_hours: u32,
}

// ==================== ENUMS ====================

#[derive(AnchorSerialize, AnchorDeserialize, Clone, PartialEq, Eq, InitSpace)]
pub enum UserRole {
    Donor,
    Ngo,
    Volunteer,
    Community,
    Admin,
}

#[derive(AnchorSerialize, AnchorDeserialize, Clone, PartialEq, Eq, InitSpace)]
pub enum DonationStatus {
    Available,
    Matched,
    Pending,
    InTransit,
    Delivered,
    Cancelled,
    Expired,
}

#[derive(AnchorSerialize, AnchorDeserialize, Clone, PartialEq, Eq, InitSpace)]
pub enum RiskScore {
    Safe,
    Conditional,
    Reject,
}

#[derive(AnchorSerialize, AnchorDeserialize, Clone, PartialEq, Eq, InitSpace)]
pub enum PickupStatus {
    Scheduled,
    InProgress,
    Completed,
    Cancelled,
}

#[derive(AnchorSerialize, AnchorDeserialize, Clone, PartialEq, Eq, InitSpace)]
pub enum DeliveryStatus {
    Scheduled,
    InProgress,
    Completed,
    Cancelled,
}

// ==================== EVENTS ====================

#[event]
pub struct UserCreated {
    pub user: Pubkey,
    pub authority: Pubkey,
    pub role: UserRole,
    pub timestamp: i64,
}

#[event]
pub struct UserProfileUpdated {
    pub user: Pubkey,
    pub timestamp: i64,
}

#[event]
pub struct UserVerified {
    pub user: Pubkey,
    pub verified_by: Pubkey,
    pub timestamp: i64,
}

#[event]
pub struct DonationCreated {
    pub donation: Pubkey,
    pub donor: Pubkey,
    pub category: String,
    pub quantity: u64,
    pub timestamp: i64,
}

#[event]
pub struct DonationMatched {
    pub donation: Pubkey,
    pub ngo: Pubkey,
    pub timestamp: i64,
}

#[event]
pub struct PickupScheduled {
    pub donation: Pubkey,
    pub volunteer: Pubkey,
    pub scheduled_time: i64,
    pub timestamp: i64,
}

#[event]
pub struct PickupCompleted {
    pub donation: Pubkey,
    pub volunteer: Pubkey,
    pub actual_quantity: u64,
    pub timestamp: i64,
}

#[event]
pub struct DeliveryScheduled {
    pub donation: Pubkey,
    pub volunteer: Pubkey,
    pub scheduled_time: i64,
    pub timestamp: i64,
}

#[event]
pub struct DeliveryCompleted {
    pub donation: Pubkey,
    pub volunteer: Pubkey,
    pub received_quantity: u64,
    pub timestamp: i64,
}

#[event]
pub struct ReputationUpdated {
    pub user: Pubkey,
    pub updated_by: Pubkey,
    pub new_score: u16,
    pub change: i16,
    pub reason: String,
    pub timestamp: i64,
}

#[event]
pub struct RewardTokenCreated {
    pub mint: Pubkey,
    pub user: Pubkey,
    pub timestamp: i64,
}

#[event]
pub struct ConfigInitialized {
    pub authority: Pubkey,
    pub timestamp: i64,
}

#[event]
pub struct ConfigUpdated {
    pub authority: Pubkey,
    pub timestamp: i64,
}

// ==================== ERRORS ====================

#[error_code]
pub enum CustomError {
    #[msg("User is not authorized to perform this action")]
    Unauthorized,
    
    #[msg("User account is inactive")]
    UserInactive,
    
    #[msg("User is already verified")]
    UserAlreadyVerified,
    
    #[msg("Invalid user role for this operation")]
    InvalidRole,
    
    #[msg("Donation is not available")]
    DonationNotAvailable,
    
    #[msg("Donation is not matched")]
    DonationNotMatched,
    
    #[msg("Donation is not in transit")]
    DonationNotInTransit,
    
    #[msg("Pickup is not scheduled")]
    PickupNotScheduled,
    
    #[msg("Delivery is not scheduled")]
    DeliveryNotScheduled,
    
    #[msg("Invalid reputation score")]
    InvalidReputationScore,
    
    #[msg("Insufficient reputation")]
    InsufficientReputation,
    
    #[msg("Operation timeout")]
    OperationTimeout,
    
    #[msg("Invalid quantity")]
    InvalidQuantity,
    
    #[msg("Invalid location")]
    InvalidLocation,
    
    #[msg("Invalid timestamp")]
    InvalidTimestamp,
    
    #[msg("Account already exists")]
    AccountAlreadyExists,
    
    #[msg("Account does not exist")]
    AccountDoesNotExist,
    
    #[msg("Invalid configuration")]
    InvalidConfig,
    
    #[msg("Rate limit exceeded")]
    RateLimitExceeded,
    
    #[msg("Insufficient funds")]
    InsufficientFunds,
    
    #[msg("Invalid token")]
    InvalidToken,
    
    #[msg("Metadata creation failed")]
    MetadataCreationFailed,
}

// ==================== UTILITIES ====================

impl Default for GlobalConfig {
    fn default() -> Self {
        Self {
            min_reputation_for_matching: 50,
            max_donations_per_day: 10,
            pickup_timeout_hours: 24,
            delivery_timeout_hours: 48,
            reputation_decay_rate: 1,
            reward_token_amount_per_donation: 100,
            co2_saved_per_kg: 2500, // grams CO2 per kg
            platform_fee_percentage: 2,
            emergency_threshold_hours: 6,
        }
    }
}
