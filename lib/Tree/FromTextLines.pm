package Tree::FromTextLines;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(build_tree_from_text_lines);

sub build_tree_from_text_lines {
    require Text::Tabs;
    require Tree::FromStruct;

    my $opts;
    if (ref($_[0]) eq 'HASH') {
        $opts = shift;
    } else {
        $opts = {};
    }
    my $text = Text::Tabs::expand(shift);

    my @structs;
    my @indents;
    my $linum = 0;
    for my $line (split /^/m, $text) {
        $linum++;
        chomp($line);

        # ignore blank lines
        next unless $line =~ /\S/;

        my $indent = length($line =~ s/^(\s+)// ? $1 : "");

        # parse line
        my %attrs = $line =~ /(\w+):(\S*)/g;
        my $struct = \%attrs;

        my $i;
        for my $j (0..$#indents) {
            if ($indent <= $indents[$j]) {
                $i = $j; last;
            }
        }
        if (!defined($i)) {
            #say "D: line $linum is more indented than previous line so it's a child";
            push @structs, $struct;
            push @indents, $indent;
            if (@structs > 1) {
                $structs[-2]{_children} //= [];
                push @{ $structs[-2]{_children} }, $struct;
            }
        } else {
            #say "D: line $linum is at level $i";
            if ($i == 0) {
                die "Line $linum: Multiple roots not allowed: $line";
            }
            splice @structs, $i;
            splice @indents, $i;

            $structs[-1]{_children} //= [];
            push @{ $structs[-1]{_children} }, $struct;

            push @structs, $struct;
            push @indents, $indent;
        }
    }

    die "Please specify one or more lines of text" unless @structs;

    Tree::FromStruct::build_tree_from_struct($structs[0]);
}

# TODO: option to parse each line as CSV line, LTSV line, JSON, or Perl hash for
# greater flexibility.

1;
# ABSTRACT: Build a tree object from lines of text, each line indented to express structure

=head1 SYNOPSIS

 use Tree::FromTextLines qw(build_tree_from_text_lines);
 use Tree::Object::Hash;

 my $tree = build_tree_from_text_lines(<<'_');
 id:root _class:Tree::Object::Hash
   id:child1 attr1:foo
   id:child2 attr1:foo attr2:bar _class:My::Node
     id:grandchild1
   id:child3
 _


=head1 DESCRIPTION


=head1 FUNCTIONS

=head2 build_tree_from_text_lines([ \%opts, ] $text) => obj

This function can be used to build a tree object from text lines. Each line
represents a node and its indentation expresses structure: line that is more
indented than its previous line signifies that the node is child of the previous
node.

This is more convenient than L<Tree::FromStruct>, but actually internally the
the text will be converted to structure to feed to Tree::FromStruct to get the
final tree object.

Each line of text by default must be in form of name-value pairs separated by
whitespaces (it will be parsed simply using Perl code C<< %attrs =
/(\w+):(\S*)/g >>), e.g.:

 id:root  attr1:foo attr2:bar

The names will become object attributes, except special names that begin with
underscore (C<_>), like C<_class>, C<_constructor>, etc. They mean the same as
in L<Text::FromStruct>.

To use this function, you must have at least one tree node class. Any class will
do as long as it responds to C<parent> and C<children> (see
L<Role::TinyCommons::Tree::Node> for more details on the requirement). Supply
the class name in C<_class> in the first line.

Available options:

=over

=back


=head1 SEE ALSO

L<Tree::FromStruct>
