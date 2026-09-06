use jmaptest;

attr pristine => 1;

# RFC 8620 Section 5.3: Empty /set result fields MUST be null, not {}

test {
  my ($self) = @_;

  my $account = $self->pristine_account;
  my $tester  = $account->tester;

  capability_check($tester,
    'urn:ietf:params:jmap:core',
    'urn:ietf:params:jmap:mail',
  ) or return;

  my $res = $tester->request([[
    "Mailbox/set" => {
      create => {
        new => {
          name => 'null fields test mailbox',
        },
      },
    },
  ]]);

  my $args = $res->single_sentence('Mailbox/set')->arguments;

  # Successful create — these should have content
  ok($args->{created}{new}, 'created has our mailbox');
  ok($args->{created}{new}{id}, 'created mailbox has id');

  # Empty result groups MUST be null per RFC 8620 Section 5.3
  is($args->{notCreated}, undef, 'notCreated is null when no errors');
  is($args->{updated}, undef, 'updated is null when no updates requested');
  is($args->{notUpdated}, undef, 'notUpdated is null when no updates requested');
  is($args->{destroyed}, undef, 'destroyed is null when no destroys requested');
  is($args->{notDestroyed}, undef, 'notDestroyed is null when no destroys requested');
};
