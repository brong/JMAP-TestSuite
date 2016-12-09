use strict;
use warnings;

use JMAP::TestSuite;
use JMAP::TestSuite::Util qw(batch_ok);

use Test::Deep::JType;
use Test::More;

use List::Util qw(first);

use Test::Differences;

my $server = JMAP::TestSuite->get_server;

$server->simple_test(sub {
  my ($context) = @_;

  my $tester = $context->tester;

  my $batch = $context->create_batch(mailbox => {
    x => { name => "Folder X at $^T.$$" },
  });

  batch_ok($batch);

  ok( $batch->is_entirely_successful, "batch succeeded fully");
  ok(my $x = $batch->result_for('x'), 'got x mailbox');
  ok( my $id = $x->id, 'got x mailbox id') or diag explain $x;
  my $mailboxid = $x->id;

  my $time = time;

  # Upload an email
  my $raw = <<"EOF";
From: "Some Example Sender" <example\@example.com>\r
To: directions-of-responsibility\@adipiscialiquam.org\r
Subject: test message\r
Date: Wed, 7 Dec 2016 01:48:15 -0500\r
MIME-Version: 1.0\r
Content-Type: text/plain; charset="UTF-8"\r
Content-Transfer-Encoding: quoted-printable\r
X-Unique: $time $$\r
\r
This is a test message.\r
EOF

  my $res = $tester->upload('message/rfc822', \$raw);
  ok($res->is_success, 'upload succeeded')
    or diag explain $res->http_response->as_string;

  my $ac_id = $res->payload->{accountId};
  my $blob_id = $res->payload->{blobId};

  ok($ac_id, 'got accountId from upload');
  ok($blob_id, 'got blob_id from upload')
    or diag explain $res->http_response->as_string;

  # Download a copy, verify
  $res = $tester->download({
    accountId => $ac_id,
    blobId    => $blob_id,
    name      => 'message.eml'
  });

  ok($res->is_success, 'download succeded');

  eq_or_diff($res->bytes_ref, $raw, 'download after upload is sane');

  # Now importing the message
  $res = $tester->request([[
    'importMessages' => {
      'messages' => {
        '1' => {
          'blobId'     => $blob_id,
          'mailboxIds' => [
            $mailboxid,
          ],
          'isFlagged'  => \0,
          'isAnswered' => \0,
          'isDraft'    => \0,
          'isUnread'   => \0
        }
      }
    }
  ]]);

  ok($res->is_success, 'importMessages looks ok');

  my $new_blob_id = $res->single_sentence->arguments->{created}{1}{blobId};
  ok($new_blob_id, 'got a new blob id after importing')
    or diag explain $res->http_response->as_string;

  isnt($new_blob_id, $blob_id, 'new blob id after import is different');

  # Ensure downloading the old blob_id still matches original
  $res = $tester->download({
    accountId => $ac_id,
    blobId    => $blob_id,
    name      => 'message.eml'
  });

  ok($res->is_success, 'download succeded');

  eq_or_diff($res->bytes_ref, $raw, 'download after upload is sane');

  # Ensure downloading new blob_id matches original
  $res = $tester->download({
    accountId => $ac_id,
    blobId    => $new_blob_id,
    name      => 'message.eml'
  });

  ok($res->is_success, 'download succeded');

  eq_or_diff($res->bytes_ref, $raw, 'download after upload is sane');
});

done_testing;
