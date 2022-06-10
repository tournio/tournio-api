module ApiHelpers
  def json
    JSON.parse(response.body)
  end

  def login_with_api(user)
    post '/login', params: {
      user: {
        email: user.email,
        password: user.password,
      }
    },
      as: :json
  end

  def full_team_test_data
    {
      'name' => 'Blood To Spare',
      'bowlers_attributes' => [
        {
          'position' => 1,
          'doubles_partner_num' => 2,
          'person_attributes' => {
            'first_name' => 'Gannon',
            'last_name' => 'Wong',
            'usbc_id' => '8673-83363',
            'igbo_id' => 'HU-8173',
            'birth_month' => '7',
            'birth_day' => '3',
            'nickname' => '',
            'phone' => '792-110-6036',
            'email' => 'cogy@gmail.com',
            'address1' => '20 Nature Ct',
            'address2' => 'Unit 9082',
            'city' => 'Boston',
            'state' => 'Ohio',
            'country' => 'US',
            'postal_code' => '54918',
          },
          'additional_question_responses' => [
            {
              'name' => 'standings_link',
              'response' => 'http://www.leaguesecretary.com',
            },
          ],
        },
        {
          'position' => 2,
          'doubles_partner_num' => 1,
          'person_attributes' => {
            'first_name' => 'Giacomo',
            'last_name' => 'Hale',
            'usbc_id' => '6621-43399',
            'igbo_id' => 'YW-5457',
            'birth_month' => '6',
            'birth_day' => '16',
            'nickname' => 'Gio',
            'phone' => '814-499-4750',
            'email' => 'lite@yahoo.com',
            'address1' => '9 Artisan Rd',
            'address2' => '',
            'city' => 'Toronto',
            'state' => 'Arkansas',
            'country' => 'CA',
            'postal_code' => '37236',
          },
          'additional_question_responses' => [
            {
              'name' => 'pronouns',
              'response' => 'something else',
            },
            {
              'name' => 'comment',
              'response' => 'I like pizza!',
            },
          ],
        },
        {
          'position' => 3,
          'doubles_partner_num' => 4,
          'person_attributes' => {
            'first_name' => 'Nelle',
            'last_name' => 'Reeves',
            'usbc_id' => '5678-97198',
            'igbo_id' => 'QU-7298',
            'birth_month' => '11',
            'birth_day' => '20',
            'nickname' => 'Whoa Nelly',
            'phone' => '881-954-9563',
            'email' => 'depozisut@gmail.com',
            'address1' => '2 California Dr',
            'address2' => '#5',
            'city' => 'Houston',
            'state' => 'Nebraska',
            'country' => 'US',
            'postal_code' => '33818',
          },
          'additional_question_responses' => [
            {
              'name' => 'comment',
              'response' => 'fe fi fo fum',
            },
          ],
        },
        {
          'position' => 4,
          'doubles_partner_num' => 3,
          'person_attributes' => {
            'first_name' => 'Gloria',
            'last_name' => 'Chang',
            'usbc_id' => '4221-66816',
            'igbo_id' => 'AP-9392',
            'birth_month' => '10',
            'birth_day' => '16',
            'nickname' => '',
            'phone' => '411-688-4762',
            'email' => 'wilogo@yahoo.com',
            'address1' => '4361 Artisan Pkwy',
            'address2' => '',
            'city' => 'Washington DC',
            'state' => 'Quebec',
            'country' => 'BM',
            'postal_code' => '22019',
          },
          'additional_question_responses' => [
            {
              'name' => 'pronouns',
              'response' => '',
            },
          ],
        },
      ],
    }
  end

  def full_team_cleaned_up_form_data
    {
      'name' => 'Blood To Spare',
      'bowlers_attributes' => [
        {
          'position' => 1,
          'doubles_partner_num' => 2,
          'person_attributes' => {
            'first_name' => 'Gannon',
            'last_name' => 'Wong',
            'usbc_id' => '8673-83363',
            'igbo_id' => 'HU-8173',
            'birth_month' => '7',
            'birth_day' => '3',
            'nickname' => '',
            'phone' => '792-110-6036',
            'email' => 'cogy@gmail.com',
            'address1' => '20 Nature Ct',
            'address2' => 'Unit 9082',
            'city' => 'Boston',
            'state' => 'Ohio',
            'country' => 'US',
            'postal_code' => '54918',
          },
          'additional_question_responses_attributes' => [
            {
              'response' => 'http://www.leaguesecretary.com',
              'extended_form_field_id' => ExtendedFormField.find_by(name: 'standings_link').id,
            },
          ],
        },
        {
          'position' => 2,
          'doubles_partner_num' => 1,
          'person_attributes' => {
            'first_name' => 'Giacomo',
            'last_name' => 'Hale',
            'usbc_id' => '6621-43399',
            'igbo_id' => 'YW-5457',
            'birth_month' => '6',
            'birth_day' => '16',
            'nickname' => 'Gio',
            'phone' => '814-499-4750',
            'email' => 'lite@yahoo.com',
            'address1' => '9 Artisan Rd',
            'address2' => '',
            'city' => 'Toronto',
            'state' => 'Arkansas',
            'country' => 'CA',
            'postal_code' => '37236',
          },
          'additional_question_responses_attributes' => [
            {
              'response' => 'something else',
              'extended_form_field_id' => ExtendedFormField.find_by(name: 'pronouns').id,
            },
            {
              'response' => 'I like pizza!',
              'extended_form_field_id' => ExtendedFormField.find_by(name: 'comment').id,
            },
          ],
        },
        {
          'position' => 3,
          'doubles_partner_num' => 4,
          'person_attributes' => {
            'first_name' => 'Nelle',
            'last_name' => 'Reeves',
            'usbc_id' => '5678-97198',
            'igbo_id' => 'QU-7298',
            'birth_month' => '11',
            'birth_day' => '20',
            'nickname' => 'Whoa Nelly',
            'phone' => '881-954-9563',
            'email' => 'depozisut@gmail.com',
            'address1' => '2 California Dr',
            'address2' => '#5',
            'city' => 'Houston',
            'state' => 'Nebraska',
            'country' => 'US',
            'postal_code' => '33818',
          },
          'additional_question_responses_attributes' => [
            {
              'response' => 'fe fi fo fum',
              'extended_form_field_id' => ExtendedFormField.find_by(name: 'comment').id,
            },
          ],
        },
        {
          'position' => 4,
          'doubles_partner_num' => 3,
          'person_attributes' => {
            'first_name' => 'Gloria',
            'last_name' => 'Chang',
            'usbc_id' => '4221-66816',
            'igbo_id' => 'AP-9392',
            'birth_month' => '10',
            'birth_day' => '16',
            'nickname' => '',
            'phone' => '411-688-4762',
            'email' => 'wilogo@yahoo.com',
            'address1' => '4361 Artisan Pkwy',
            'address2' => '',
            'city' => 'Washington DC',
            'state' => 'Quebec',
            'country' => 'BM',
            'postal_code' => '22019',
          },
        },
      ],
    }
  end

  def partial_team_test_data
    {
      'name' => 'Strike Out',
      'bowlers_attributes' => [
        {
          'position' => 1,
          'doubles_partner_num' => 2,
          'person_attributes' => {
            'first_name' => 'Gannon',
            'last_name' => 'Wong',
            'usbc_id' => '8673-83363',
            'igbo_id' => 'HU-8173',
            'birth_month' => '7',
            'birth_day' => '3',
            'nickname' => '',
            'phone' => '792-110-6036',
            'email' => 'cogy@gmail.com',
            'address1' => '20 Nature Ct',
            'address2' => 'Unit 9082',
            'city' => 'Boston',
            'state' => 'Ohio',
            'country' => 'US',
            'postal_code' => '54918',
          },
          'additional_question_responses' => [
            {
              'name' => 'standings_link',
              'response' => 'http://www.leaguesecretary.com',
            },
          ],
        },
        {
          'position' => 2,
          'doubles_partner_num' => 1,
          'person_attributes' => {
            'first_name' => 'Giacomo',
            'last_name' => 'Hale',
            'usbc_id' => '6621-43399',
            'igbo_id' => 'YW-5457',
            'birth_month' => '6',
            'birth_day' => '16',
            'nickname' => 'Gio',
            'phone' => '814-499-4750',
            'email' => 'lite@yahoo.com',
            'address1' => '9 Artisan Rd',
            'address2' => '',
            'city' => 'Toronto',
            'state' => 'Arkansas',
            'country' => 'CA',
            'postal_code' => '37236',
          },
          'additional_question_responses' => [
            {
              'name' => 'pronouns',
              'response' => 'something else',
            },
            {
              'name' => 'comment',
              'response' => 'I like pizza!',
            },
          ],
        },
        {
          'position' => 3,
          'doubles_partner_num' => nil,
          'person_attributes' => {
            'first_name' => 'Nelle',
            'last_name' => 'Reeves',
            'usbc_id' => '5678-97198',
            'igbo_id' => 'QU-7298',
            'birth_month' => '11',
            'birth_day' => '20',
            'nickname' => 'Whoa Nelly',
            'phone' => '881-954-9563',
            'email' => 'depozisut@gmail.com',
            'address1' => '2 California Dr',
            'address2' => '#5',
            'city' => 'Houston',
            'state' => 'Nebraska',
            'country' => 'US',
            'postal_code' => '33818',
          },
          'additional_question_responses' => [
            {
              'name' => 'comment',
              'response' => 'fe fi fo fum',
            },
          ],
        },
      ],
      'options' => {
        'place_with_others' => true,
      }
    }
  end

  def invalid_team_test_data
    {
      'name' => 'Gutter Lovers',
      'bowlers_attributes' => [
        {
          'position' => 1,
          'doubles_partner_num' => 2,
          'person_attributes' => {
            'first_name' => 'Gannon',
            'last_name' => '',
            'usbc_id' => '8673-83363',
            'igbo_id' => 'HU-8173',
            'birth_month' => '7',
            'birth_day' => '3',
            'nickname' => '',
            'phone' => '792-110-6036',
            'email' => 'cogy@gmail.com',
            'address1' => '20 Nature Ct',
            'address2' => 'Unit 9082',
            'city' => 'Boston',
            'state' => 'Ohio',
            'country' => 'US',
            'postal_code' => '54918',
          },
          'additional_question_responses' => [
            {
              'name' => 'standings_link',
              'response' => 'http://www.leaguesecretary.com',
            },
          ],
        },
        {
          'position' => 2,
          'doubles_partner_num' => 1,
          'person_attributes' => {
            'first_name' => 'Giacomo',
            'last_name' => 'Hale',
            'usbc_id' => '6621-43399',
            'igbo_id' => 'YW-5457',
            'birth_month' => '6',
            'birth_day' => '16',
            'nickname' => 'Gio',
            'phone' => '814-499-4750',
            'email' => 'lite@yahoo.com',
            'address1' => '9 Artisan Rd',
            'address2' => '',
            'city' => 'Toronto',
            'state' => 'Arkansas',
            'country' => 'CA',
            'postal_code' => '37236',
          },
          'additional_question_responses' => [
            {
              'name' => 'pronouns',
              'response' => 'something else',
            },
            {
              'name' => 'comment',
              'response' => 'I like pizza!',
            },
          ],
        },
      ],
    }
  end

  def create_bowler_test_data
    {
      'person_attributes' => {
        'first_name' => 'Giacomo',
        'last_name' => 'Hale',
        'usbc_id' => '6621-43399',
        # 'igbo_id' => 'YW-5457',
        'birth_month' => '6',
        'birth_day' => '16',
        'nickname' => 'Gio',
        'phone' => '814-499-4750',
        'email' => 'lite@yahoo.com',
        'address1' => '9 Artisan Rd',
        'address2' => '',
        'city' => 'Toronto',
        'state' => 'Arkansas',
        'country' => 'CA',
        'postal_code' => '37236',
      },
      'additional_question_responses' => [
        {
          'name' => 'pronouns',
          'response' => 'something else',
        },
        {
          'name' => 'comment',
          'response' => 'I like pizza!',
        },
      ],
    }
  end

  def invalid_create_bowler_test_data
    {
      'person_attributes' => {
        'first_name' => 'Giacomo',
        'last_name' => 'Hale',
        'usbc_id' => '6621-43399',
        'igbo_id' => 'YW-5457',
        'birth_month' => '6',
        'birth_day' => '16',
        'nickname' => 'Gio',
        'phone' => '814-499-4750',
        # 'email' => 'lite@yahoo.com',
        'address1' => '9 Artisan Rd',
        'address2' => '',
        'city' => 'Toronto',
        'state' => 'Arkansas',
        'country' => 'CA',
        'postal_code' => '37236',
      },
      'additional_question_responses' => [
        {
          'name' => 'pronouns',
          'response' => 'something else',
        },
        {
          'name' => 'comment',
          'response' => 'I like pizza!',
        },
      ],
    }
  end

  def create_doubles_test_data
    [
      {
        'person_attributes' => {
          'first_name' => 'Natalie',
          'last_name' => 'Wood',
          'usbc_id' => '6621-43399',
          # 'igbo_id' => 'YW-5457',
          'birth_month' => '6',
          'birth_day' => '16',
          'nickname' => 'Nat',
          'phone' => '814-499-4750',
          'email' => 'natalie@woodd.com',
          'address1' => '9 Artisan Rd',
          'address2' => '',
          'city' => 'Toronto',
          'state' => 'Arkansas',
          'country' => 'CA',
          'postal_code' => '37236',
        },
        'additional_question_responses' => [
          {
            'name' => 'pronouns',
            'response' => 'she/her',
          },
          {
            'name' => 'comment',
            'response' => 'I like pizza!',
          },
        ],
      },
      {
        'person_attributes' => {
          'first_name' => 'Bowen',
          'last_name' => 'Yang',
          'usbc_id' => '656-3245',
          # 'igbo_id' => 'YW-5457',
          'birth_month' => '7',
          'birth_day' => '4',
          'phone' => '814-555-0000',
          'email' => 'bowenyang@snl.ny.us',
          'address1' => '30 Rockefeller Plaza',
          'address2' => 'Studio 8H',
          'city' => 'New York City',
          'state' => 'New York',
          'country' => 'US',
          'postal_code' => '12345',
        },
        'additional_question_responses' => [
          {
            'name' => 'pronouns',
            'response' => 'he/him',
          },
          {
            'name' => 'comment',
            'response' => 'You think yer funny?',
          },
        ],
      },
    ]
  end

end
