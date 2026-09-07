use jmaptest;

# Naming a real account outside this session must fail with accountNotFound
# (RFC 8620 §3.6.2), exactly as an unknown id does.

attr pristine => 1;

test {
  my ($self) = @_;

  my $account = $self->any_account;
  my $other   = $self->pristine_account;

  capability_check($account->tester,
    'urn:ietf:params:jmap:core',
    'urn:ietf:params:jmap:mail',
  ) or return;

  foreign_account_ok($account, $other, [
    [ 'Mailbox/get'          => { ids => [] } ],
    [ 'Mailbox/changes'      => { sinceState => '0' } ],
    [ 'Mailbox/query'        => {} ],
    [ 'Mailbox/queryChanges' => { sinceQueryState => '0' } ],
    [ 'Mailbox/set'          => {} ],
  ]);
};
