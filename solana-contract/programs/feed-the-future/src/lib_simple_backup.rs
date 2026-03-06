use anchor_lang::prelude::*;

declare_id!("F1T3F11111111111111111111111111111111111111");

#[program]
pub mod feed_the_future {
    use super::*;

    pub fn initialize_user(
        ctx: Context<InitializeUser>,
        username: String,
    ) -> Result<()> {
        let user = &mut ctx.accounts.user;
        user.authority = ctx.accounts.authority.key();
        user.username = username;
        user.bump = ctx.bumps.user;
        Ok(())
    }
}

#[derive(Accounts)]
pub struct InitializeUser<'info> {
    #[account(
        init,
        payer = authority,
        space = 8 + 32 + 50,
        seeds = [b"user", authority.key().as_ref()],
        bump
    )]
    pub user: Account<'info, UserAccount>,
    #[account(mut)]
    pub authority: Signer<'info>,
    pub system_program: Program<'info, System>,
}

#[account]
pub struct UserAccount {
    pub authority: Pubkey,
    #[max_len(50)]
    pub username: String,
    pub bump: u8,
}
