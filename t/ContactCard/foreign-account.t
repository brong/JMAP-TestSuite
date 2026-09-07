use jmaptest;

# An accountId that names a real account on this server, but one this login
# cannot see, must be accountNotFound (RFC 8620 §3.6.2) -- indistinguishable
# from an id that does not exist at all. The other account comes from
# pristine_account, which every adapter provisions outside the caller's session.

attr pristine => 1;

test {
  my ($self) = @_;

  my $account = $self->any_account;
  my $other   = $self->pristine_account;

  capability_check($account->tester,
    'urn:ietf:params:jmap:core',
    'urn:ietf:params:jmap:contacts',
  ) or return;

  foreign_account_ok($account, $other, [
    [ 'ContactCard/get'          => { ids => [] } ],
    [ 'ContactCard/changes'      => { sinceState => '0' } ],
    [ 'ContactCard/query'        => {} ],
    [ 'ContactCard/queryChanges' => { sinceQueryState => '0' } ],
    [ 'ContactCard/set'          => {} ],
    [ 'ContactCard/copy'         => { fromAccountId => 'SELF',  accountId => 'OTHER', create => {} } ],
    [ 'ContactCard/copy'         => { fromAccountId => 'OTHER', accountId => 'SELF',  create => {} } ],
  ]);
};
