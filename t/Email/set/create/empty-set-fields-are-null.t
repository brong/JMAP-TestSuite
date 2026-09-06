use jmaptest;

# RFC 8620 Section 5.3: Empty /set result fields MUST be null, not {}
# "created": "Id[Foo]|null" — null if nothing was created
# "notCreated": "Id[SetError]|null" — null if no errors

test {
  my ($self) = @_;

  my $account = $self->any_account;
  my $tester  = $account->tester;

  capability_check($tester,
    'urn:ietf:params:jmap:core',
    'urn:ietf:params:jmap:mail',
  ) or return;

  # Email/set with only a create — notUpdated, notDestroyed, updated,
  # destroyed should all be null
  my $mailbox = $account->create_mailbox;

  my $res = $tester->request([[
    "Email/set" => {
      create => {
        new => {
          mailboxIds => { $mailbox->id => \1 },
          from       => [{ email => 'test@example.com' }],
          subject    => 'null fields test',
          bodyValues => { '1' => { value => 'test body' } },
          # RFC 8621 S4.6 requires text/plain here; explicit, because a strict
          # server may reject the create rather than infer the MIME default.
          textBody   => [{ partId => '1', type => 'text/plain' }],
        },
      },
    },
  ]]);

  my $args = $res->single_sentence('Email/set')->arguments;

  # Successful create — these should have content
  ok($args->{created}{new}, 'created has our email');
  ok($args->{created}{new}{id}, 'created email has id');

  # Empty result groups MUST be null per RFC 8620 Section 5.3
  is($args->{notCreated}, undef, 'notCreated is null when no errors');
  is($args->{updated}, undef, 'updated is null when no updates requested');
  is($args->{notUpdated}, undef, 'notUpdated is null when no updates requested');
  is($args->{destroyed}, undef, 'destroyed is null when no destroys requested');
  is($args->{notDestroyed}, undef, 'notDestroyed is null when no destroys requested');
};
