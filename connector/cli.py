import click
import cli_impl as impl

@click.group()
def cli():
    pass

@click.command()
@click.argument("block-header")
@click.option("--sim",is_flag=True, default=False, help="Send request against simulation.")
@click.option("-f","--follow",is_flag=True, default=False,help="Read hash and nonce until a valid is found.")
def mine(sim, block_header, follow):
    '''Sends the given header to the FPGA.'''
    protocol = impl.getProtocol(sim)
    impl.mine(protocol, block_header, follow)


@click.command()
@click.option("--sim",is_flag=True, default=False, help="Send request against simulation.")
@click.option("-f","--follow",is_flag=True, default=False,help="Read hash and nonce until a valid is found.")
def readResult(sim, follow):
    '''Reads the current nonce and the found bit.'''
    protocol = impl.getProtocol(sim)
    impl.readResult(protocol, repeated=follow)


@click.command()
@click.option("--sim",is_flag=True, default=False, help="Send request against simulation.")
@click.option("-f","--follow",is_flag=True, default=False,help="Read hash and nonce until a valid is found.")
def test(sim, follow):
    '''Sends a `correct` test header to FPGA.'''
    protocol = impl.getProtocol(sim)
    impl.sendTestHeader(protocol, follow)

@click.command()
@click.option("--sim",is_flag=True, default=False, help="Send request against simulation.")
def count(sim):
    '''Counts the number of tested nonces.'''
    protocol = impl.getProtocol(sim)
    impl.count(protocol)

cli.add_command(mine)
cli.add_command(readResult)
cli.add_command(test)
cli.add_command(count)

if __name__ == "__main__":
    cli()
