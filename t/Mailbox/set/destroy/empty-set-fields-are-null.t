use jmaptest;

# RFC 8620 Section 5.3: Empty /set result fields MUST be null, not {}

test {
  my ($self) = @_;

  my $account = $self->any_account;
  my $tester  = $account->tester;

  capability_check($tester,
    'urn:ietf:params:jmap:core',
    'urn:ietf:params:jmap:mail',
  ) or return;

  # Create a mailbox to destroy
  my $mailbox = $account->create_mailbox({ name => 'to-destroy' });

  my $res = $tester->request([[
    "Mailbox/set" => {
      destroy => [ $mailbox->id ],
    },
  ]]);

  my $args = $res->single_sentence('Mailbox/set')->arguments;

  # Successful destroy — should have content
  ok($args->{destroyed}, 'destroyed is not null');
  is(scalar @{$args->{destroyed}}, 1, 'destroyed has one mailbox');

  # Empty result groups MUST be null per RFC 8620 Section 5.3
  is($args->{created}, undef, 'created is null when no creates requested');
  is($args->{notCreated}, undef, 'notCreated is null when no creates requested');
  is($args->{updated}, undef, 'updated is null when no updates requested');
  is($args->{notUpdated}, undef, 'notUpdated is null when no updates requested');
  is($args->{notDestroyed}, undef, 'notDestroyed is null when no errors');
};
