return {
    -- This is a default group only for visual when group is false (Don't change 'default' name)
    ['default'] = {
        label = 'Civilian',
        cat = 'CIV',
        grades = {
            [1] = { label = 'Unemployed' },
        },
    },
    ['lspd'] = {
        label = 'LSPD',
        cat = 'GOV',
        grades = {
            [1] = { label = 'Police Officer I' },
            [2] = { label = 'Police Officer II' },
            [3] = { label = 'Police Officer III' },
            [4] = { label = 'Detective' },
            [5] = { label = 'Sergeant I' },
            [6] = { label = 'Sergeant II' },
            [7] = { label = 'Lieutenant I' },
            [8] = { label = 'Lieutenant II' },
            [9] = { label = 'Captain I' },
            [10] = { label = 'Captain II' },
            [11] = { label = 'Captain III' },
            [12] = { label = 'Commander' },
            [13] = { label = 'Deputy Chief' },
            [14] = { label = 'Assistant Chief' },
            [15] = { label = 'Chief' },
        },
        bossPerms = {
            [14] = { promote = true, hire = true },
            [15] = { promote = true, hire = true, fire = true },
        },
        fundPerms = {
            [14] = { view = true, deposit = true },
            [15] = { view = true, deposit = true, withdraw = true },
        },
    },
    ['lsmd'] = {
        label = 'LSMD',
        cat = 'EMS',
        grades = {
            [1] = { label = 'Observer' },
            [2] = { label = 'Medical Student I' },
            [3] = { label = 'Medical Student II' },
            [4] = { label = 'Intern' },
            [5] = { label = 'Junior Resident' },
            [6] = { label = 'Resident' },
            [7] = { label = 'Senior Resident' },
            [8] = { label = 'Chief Resident' },
            [9] = { label = 'Fellow' },
            [10] = { label = 'Attending Physician' },
            [11] = { label = 'Senior Attending' },
            [12] = { label = 'Specialist / Surgeon' },
            [13] = { label = 'Senior Surgeon' },
            [14] = { label = 'Head of Department' },
            [15] = { label = 'Medical Director' },
        },
        bossPerms = {
            [14] = { promote = true, hire = true },
            [15] = { promote = true, hire = true, fire = true },
        },
        fundPerms = {
            [14] = { view = true, deposit = true },
            [15] = { view = true, deposit = true, withdraw = true },
        },
    },
    ['cartel'] = {
        label = 'Cartel',
        cat = 'ILG',
        grades = {
            [1] = { label = 'Recruit' },
            [2] = { label = 'Member' },
            [3] = { label = 'OG' },
            [4] = { label = 'Underboss' },
            [5] = { label = 'Boss' },
        },
        bossPerms = {
            [4] = { promote = true, hire = true },
            [5] = { promote = true, hire = true, fire = true },
        },
        fundPerms = {
            [4] = { view = true, deposit = true },
            [5] = { view = true, deposit = true, withdraw = true },
        },
    },
}