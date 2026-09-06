use jmaptest;

attr pristine => 1;

test {
  my ($self) = @_;

  my $account = $self->pristine_account;
  my $tester  = $account->tester;

  capability_check($tester,
    'urn:ietf:params:jmap:core',
    'urn:ietf:params:jmap:mail',
  ) or return;

  my $mailbox = $account->create_mailbox;

  my $blob = $account->email_blob(generic => {});
  ok($blob->is_success, 'uploaded blob');

  # Read the state AFTER all setup. Nothing forbids a server from advancing
  # the Email state for its own reasons -- Cyrus moves it on a blob upload --
  # so a state fetched before the setup is not necessarily still current, and
  # this test is about ifInState being honoured, not about what moves state.
  my $state_res = $tester->request([[
    "Email/get" => { ids => [] },
  ]]);
  my $state = $state_res->single_sentence('Email/get')->arguments->{state};
  ok($state, 'got current state');

  subtest "correct ifInState is accepted" => sub {
    my $set_res = $tester->request([[
      "Email/set" => {
        ifInState => $state,
        create => {
          new1 => {
            mailboxIds => { $mailbox->id => JSON::true },
            subject    => "Test",
            bodyStructure => {
              type    => 'text/plain',
              partId  => 'body',
            },
            bodyValues => {
              body => { value => "Test body" },
            },
          },
        },
      },
    ]]);

    jcmp_deeply(
      $set_res->single_sentence('Email/set')->arguments->{created},
      superhashof({ new1 => ignore() }),
      'email created with correct ifInState'
    );
  };

  subtest "wrong ifInState returns stateMismatch" => sub {
    my $set_res = $tester->request([[
      "Email/set" => {
        ifInState => "bogus-state-that-does-not-exist",
        create => {
          new2 => {
            mailboxIds => { $mailbox->id => JSON::true },
            subject    => "Test 2",
            bodyStructure => {
              type    => 'text/plain',
              partId  => 'body',
            },
            bodyValues => {
              body => { value => "Test body 2" },
            },
          },
        },
      },
    ]]);

    jcmp_deeply(
      $set_res->single_sentence('error')->arguments,
      superhashof({ type => 'stateMismatch' }),
      'got stateMismatch error for wrong ifInState'
    );
  };
};
